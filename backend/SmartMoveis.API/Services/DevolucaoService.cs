using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Infraestrutura;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

public interface IDevolucaoService
{
    Task<ResultadoServico<object>> CriarAsync(int vendaId, CriarDevolucaoDto dto);
    Task<List<object>> ListarAsync();
}

/// <summary>
/// Devolução total ou parcial de venda:
/// 1. confere se cada quantidade cabe no que ainda não foi devolvido;
/// 2. devolve os produtos ao estoque;
/// 3. abate o valor das parcelas a receber ainda em aberto (da última
///    para a primeira);
/// 4. se o cliente já tinha pago a parte devolvida, gera um reembolso
///    (conta a pagar), já pago ou em aberto;
/// 5. atualiza a situação da venda (devolvida parcial ou total).
/// </summary>
public class DevolucaoService : IDevolucaoService
{
    private readonly ApplicationDbContext _context;
    private readonly IUsuarioAtual _usuario;

    public DevolucaoService(ApplicationDbContext context, IUsuarioAtual usuario)
    {
        _context = context;
        _usuario = usuario;
    }

    public async Task<List<object>> ListarAsync()
    {
        var lista = await _context.Devolucoes
            .AsNoTracking()
            .OrderByDescending(d => d.CriadoEm)
            .Select(d => new
            {
                d.Id,
                d.VendaId,
                Cliente = d.Venda!.Cliente!.Nome,
                d.Motivo,
                d.ValorTotal,
                d.UsuarioNome,
                d.CriadoEm,
                Itens = d.Itens.Select(i => new
                {
                    i.ProdutoId,
                    Produto = i.Produto!.Nome,
                    i.Quantidade,
                    i.Subtotal
                })
            })
            .Take(300)
            .ToListAsync();

        return lista.Cast<object>().ToList();
    }

    public async Task<ResultadoServico<object>> CriarAsync(int vendaId, CriarDevolucaoDto dto)
    {
        var venda = await _context.Vendas
            .Include(v => v.Itens)
            .Include(v => v.Cliente)
            .FirstOrDefaultAsync(v => v.Id == vendaId);

        if (venda == null)
        {
            return ResultadoServico<object>.NaoEncontrado("Venda não encontrada.");
        }

        if (venda.Status == StatusVenda.Devolvida)
        {
            return ResultadoServico<object>.Conflito("Esta venda já foi totalmente devolvida.");
        }

        var pedidos = dto.Itens
            .GroupBy(i => i.ItemVendaId)
            .Select(g => new { ItemVendaId = g.Key, Quantidade = g.Sum(i => i.Quantidade) })
            .ToList();

        var devolucao = new Devolucao
        {
            VendaId = venda.Id,
            Motivo = dto.Motivo.Trim(),
            UsuarioNome = _usuario.Nome,
            CriadoEm = DateTime.UtcNow
        };

        foreach (var pedido in pedidos)
        {
            var item = venda.Itens.FirstOrDefault(i => i.Id == pedido.ItemVendaId);

            if (item == null)
            {
                return ResultadoServico<object>.Invalido(
                    $"O item {pedido.ItemVendaId} não pertence à venda #{venda.Id}.");
            }

            var disponivel = item.Quantidade - item.QuantidadeDevolvida;

            if (pedido.Quantidade > disponivel)
            {
                var produtoNome = await _context.Produtos
                    .Where(p => p.Id == item.ProdutoId)
                    .Select(p => p.Nome)
                    .FirstOrDefaultAsync();

                return ResultadoServico<object>.Invalido(new
                {
                    mensagem = $"Quantidade maior do que a disponível para devolução de {produtoNome}.",
                    disponivel,
                    solicitada = pedido.Quantidade
                });
            }

            var produto = await _context.Produtos.FirstAsync(p => p.Id == item.ProdutoId);
            produto.QuantidadeEstoque += pedido.Quantidade;

            item.QuantidadeDevolvida += pedido.Quantidade;

            var subtotal = item.PrecoUnitario * pedido.Quantidade;

            devolucao.Itens.Add(new ItemDevolucao
            {
                ItemVendaId = item.Id,
                ProdutoId = item.ProdutoId,
                Quantidade = pedido.Quantidade,
                PrecoUnitario = item.PrecoUnitario,
                Subtotal = subtotal
            });

            devolucao.ValorTotal += subtotal;
        }

        venda.ValorDevolvido += devolucao.ValorTotal;
        venda.Status = venda.Itens.All(i => i.QuantidadeDevolvida >= i.Quantidade)
            ? StatusVenda.Devolvida
            : StatusVenda.DevolvidaParcial;

        await using var transacao = await _context.Database.BeginTransactionAsync();

        _context.Devolucoes.Add(devolucao);
        await _context.SaveChangesAsync();

        var ajuste = await AjustarFinanceiroAsync(venda, devolucao, dto.FormaReembolso);

        await _context.SaveChangesAsync();
        await transacao.CommitAsync();

        return ResultadoServico<object>.Ok(new
        {
            mensagem = venda.Status == StatusVenda.Devolvida
                ? "Venda devolvida por completo. Estoque e financeiro atualizados."
                : "Devolução parcial registrada. Estoque e financeiro atualizados.",
            devolucao.Id,
            devolucao.VendaId,
            devolucao.ValorTotal,
            statusVenda = venda.Status,
            abatidoEmAberto = ajuste.Abatido,
            reembolso = ajuste.Reembolso
        });
    }

    private async Task<(decimal Abatido, object? Reembolso)> AjustarFinanceiroAsync(
        Venda venda,
        Devolucao devolucao,
        string? formaReembolso)
    {
        var restante = devolucao.ValorTotal;
        decimal abatido = 0;

        var abertas = await _context.ContasFinanceiras
            .Where(c =>
                c.VendaId == venda.Id &&
                c.Tipo == TipoConta.Receber &&
                c.Status == StatusConta.Aberta)
            .OrderByDescending(c => c.NumeroParcela)
            .ToListAsync();

        foreach (var conta in abertas)
        {
            if (restante <= 0) break;

            var reduzir = Math.Min(conta.Valor, restante);
            conta.Valor -= reduzir;
            restante -= reduzir;
            abatido += reduzir;

            var historico = new HistoricoContaFinanceira
            {
                ContaFinanceiraId = conta.Id,
                Acao = conta.Valor == 0 ? "Cancelada" : "Ajustada",
                Detalhe = $"Devolução #{devolucao.Id}: abatido R$ {reduzir:N2}",
                UsuarioNome = _usuario.Nome
            };

            if (conta.Valor == 0)
            {
                // Mantém o valor original visível na consulta.
                conta.Valor = reduzir;
                conta.Status = StatusConta.Cancelada;
                conta.Observacao = $"Cancelada pela devolução #{devolucao.Id}.";
            }

            _context.HistoricoContasFinanceiras.Add(historico);
        }

        if (restante <= 0)
        {
            return (abatido, null);
        }

        // O cliente já pagou a parte devolvida: gera o reembolso.
        var reembolso = FinanceiroService.GerarParcelas(
            new ContaFinanceira
            {
                Tipo = TipoConta.Pagar,
                Origem = OrigemConta.Devolucao,
                Descricao = $"Reembolso da devolução #{devolucao.Id} (venda #{venda.Id}) - {venda.Cliente?.Nome}",
                VendaId = venda.Id,
                DevolucaoId = devolucao.Id,
                ClienteId = venda.ClienteId
            },
            restante,
            1,
            DateTime.Today,
            _usuario.Nome)[0];

        if (!string.IsNullOrWhiteSpace(formaReembolso))
        {
            FinanceiroService.AplicarBaixa(
                reembolso, DateTime.Today, formaReembolso, restante,
                "Reembolso pago no ato da devolução.", _usuario.Nome);
        }

        _context.ContasFinanceiras.Add(reembolso);

        return (abatido, new
        {
            valor = restante,
            pago = reembolso.Status == StatusConta.Paga,
            forma = reembolso.FormaPagamento
        });
    }
}
