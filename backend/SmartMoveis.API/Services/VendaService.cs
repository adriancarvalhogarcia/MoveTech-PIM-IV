using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Infraestrutura;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

public interface IVendaService
{
    Task<IEnumerable<object>> ListarAsync();
    Task<ResultadoServico<object>> ObterAsync(int id);
    Task<ResultadoServico<VendaCriada>> CriarAsync(CriarVendaDto dto);
}

/// <summary>Venda recém-criada: o Id (para o cabeçalho Location) e o corpo da resposta.</summary>
public record VendaCriada(int Id, object Resposta);

/// <summary>
/// Regras de negócio das vendas: valida cliente e produtos, confere o
/// estoque, calcula os valores, dá baixa no estoque e gera as contas a
/// receber de acordo com a forma de pagamento.
/// </summary>
public class VendaService : IVendaService
{
    private readonly ApplicationDbContext _context;
    private readonly IUsuarioAtual _usuario;

    public VendaService(ApplicationDbContext context, IUsuarioAtual usuario)
    {
        _context = context;
        _usuario = usuario;
    }

    public async Task<IEnumerable<object>> ListarAsync()
    {
        var vendas = await _context.Vendas
            .OrderByDescending(v => v.CriadoEm)
            .Select(v => new
            {
                v.Id,
                v.ClienteId,

                Cliente = new
                {
                    v.Cliente!.Id,
                    v.Cliente.Nome
                },

                v.ValorTotal,
                v.CriadoEm,
                v.FormaPagamento,
                v.Parcelas,
                v.ValorDevolvido,
                v.Status,

                Itens = v.Itens.Select(i => new
                {
                    i.Id,
                    i.ProdutoId,

                    Produto = new
                    {
                        i.Produto!.Id,
                        i.Produto.Nome
                    },

                    i.Quantidade,
                    i.QuantidadeDevolvida,
                    i.PrecoUnitario,
                    i.Subtotal
                })
            })
            .ToListAsync();

        return vendas;
    }

    public async Task<ResultadoServico<object>> ObterAsync(int id)
    {
        var venda = await _context.Vendas
            .Where(v => v.Id == id)
            .Select(v => new
            {
                v.Id,
                v.ClienteId,

                Cliente = new
                {
                    v.Cliente!.Id,
                    v.Cliente.Nome
                },

                v.ValorTotal,
                v.CriadoEm,
                v.FormaPagamento,
                v.Parcelas,
                v.ValorDevolvido,
                v.Status,

                Itens = v.Itens.Select(i => new
                {
                    i.Id,
                    i.ProdutoId,

                    Produto = new
                    {
                        i.Produto!.Id,
                        i.Produto.Nome
                    },

                    i.Quantidade,
                    i.QuantidadeDevolvida,
                    i.PrecoUnitario,
                    i.Subtotal
                }),

                Devolucoes = v.Devolucoes
                    .OrderBy(d => d.CriadoEm)
                    .Select(d => new
                    {
                        d.Id,
                        d.Motivo,
                        d.ValorTotal,
                        d.UsuarioNome,
                        d.CriadoEm,
                        Itens = d.Itens.Select(di => new
                        {
                            di.ItemVendaId,
                            di.ProdutoId,
                            Produto = di.Produto!.Nome,
                            di.Quantidade,
                            di.Subtotal
                        })
                    })
            })
            .FirstOrDefaultAsync();

        return venda == null
            ? ResultadoServico<object>.NaoEncontrado("Venda não encontrada.")
            : ResultadoServico<object>.Ok(venda);
    }

    public async Task<ResultadoServico<VendaCriada>> CriarAsync(CriarVendaDto dto)
    {
        var cliente = await _context.Clientes
            .FirstOrDefaultAsync(c => c.Id == dto.ClienteId && c.Ativo);

        if (cliente == null)
        {
            return ResultadoServico<VendaCriada>.Invalido("Cliente não encontrado ou inativo.");
        }

        if (dto.Itens == null || dto.Itens.Count == 0)
        {
            return ResultadoServico<VendaCriada>.Invalido("A venda deve possuir pelo menos um item.");
        }

        var forma = string.IsNullOrWhiteSpace(dto.FormaPagamento)
            ? FormasPagamento.NaoInformada
            : dto.FormaPagamento;

        var aVista = FormasPagamento.AVista.Contains(forma);

        if (aVista && dto.Parcelas > 1)
        {
            return ResultadoServico<VendaCriada>.Invalido(
                "Dinheiro, Pix e cartão de débito são recebidos à vista (1 parcela).");
        }

        var parcelas = aVista || forma == FormasPagamento.NaoInformada ? 1 : dto.Parcelas;

        /*
         * O mesmo produto pode aparecer mais de uma vez na requisição.
         * As quantidades são somadas antes de conferir o estoque, para
         * que a soma nunca ultrapasse o estoque disponível.
         */
        var itensAgrupados = dto.Itens
            .GroupBy(i => i.ProdutoId)
            .Select(g => new
            {
                ProdutoId = g.Key,
                Quantidade = g.Sum(i => i.Quantidade)
            })
            .ToList();

        var venda = new Venda
        {
            ClienteId = cliente.Id,
            CriadoEm = DateTime.UtcNow,
            ValorTotal = 0,
            FormaPagamento = forma,
            Parcelas = parcelas,
            Status = StatusVenda.Concluida
        };

        decimal valorTotal = 0;

        foreach (var item in itensAgrupados)
        {
            var produto = await _context.Produtos
                .FirstOrDefaultAsync(p => p.Id == item.ProdutoId && p.Ativo);

            if (produto == null)
            {
                return ResultadoServico<VendaCriada>.Invalido(
                    $"Produto ID {item.ProdutoId} não encontrado ou inativo.");
            }

            if (produto.QuantidadeEstoque < item.Quantidade)
            {
                return ResultadoServico<VendaCriada>.Invalido(new
                {
                    mensagem = $"Estoque insuficiente para o produto {produto.Nome}.",
                    estoqueDisponivel = produto.QuantidadeEstoque,
                    quantidadeSolicitada = item.Quantidade
                });
            }

            var subtotal = produto.Preco * item.Quantidade;

            venda.Itens.Add(new ItemVenda
            {
                ProdutoId = produto.Id,
                Quantidade = item.Quantidade,
                PrecoUnitario = produto.Preco,
                Subtotal = subtotal
            });

            valorTotal += subtotal;

            produto.QuantidadeEstoque -= item.Quantidade;
        }

        venda.ValorTotal = valorTotal;

        // Venda, itens, baixa de estoque e contas a receber são gravados
        // na mesma transação: ou tudo é salvo, ou nada é salvo.
        await using var transacao = await _context.Database.BeginTransactionAsync();

        _context.Vendas.Add(venda);
        await _context.SaveChangesAsync();

        var contas = GerarContasReceber(venda, cliente, forma, parcelas);
        _context.ContasFinanceiras.AddRange(contas);
        await _context.SaveChangesAsync();

        await transacao.CommitAsync();

        return ResultadoServico<VendaCriada>.Ok(new VendaCriada(venda.Id, new
        {
            venda.Id,
            venda.ClienteId,
            cliente = cliente.Nome,
            venda.ValorTotal,
            venda.CriadoEm,
            venda.FormaPagamento,
            venda.Parcelas,
            venda.Status,
            Itens = venda.Itens.Select(i => new
            {
                i.Id,
                i.ProdutoId,
                i.Quantidade,
                i.PrecoUnitario,
                i.Subtotal
            }),
            ContasReceber = contas.Select(c => new
            {
                c.Id,
                c.NumeroParcela,
                c.Valor,
                c.Vencimento,
                c.Status
            })
        }));
    }

    /// <summary>
    /// À vista (dinheiro, Pix, débito): uma conta já recebida.
    /// Cartão de crédito, boleto e crediário: parcelas mensais em aberto,
    /// a primeira vencendo em 30 dias.
    /// Sem forma informada: uma conta em aberto vencendo hoje.
    /// </summary>
    private List<ContaFinanceira> GerarContasReceber(
        Venda venda,
        Cliente cliente,
        string forma,
        int parcelas)
    {
        var hoje = DateTime.Today;
        var aVista = FormasPagamento.AVista.Contains(forma);

        var primeiroVencimento = aVista || forma == FormasPagamento.NaoInformada
            ? hoje
            : hoje.AddMonths(1);

        var contas = FinanceiroService.GerarParcelas(
            new ContaFinanceira
            {
                Tipo = TipoConta.Receber,
                Origem = OrigemConta.Venda,
                Descricao = $"Venda #{venda.Id} - {cliente.Nome}",
                VendaId = venda.Id,
                ClienteId = cliente.Id,
                Observacao = forma == FormasPagamento.NaoInformada
                    ? "Forma de pagamento não informada na venda."
                    : $"Forma combinada: {forma}"
            },
            venda.ValorTotal,
            parcelas,
            primeiroVencimento,
            _usuario.Nome);

        if (aVista)
        {
            FinanceiroService.AplicarBaixa(
                contas[0], hoje, forma, contas[0].Valor,
                null, _usuario.Nome);
        }

        return contas;
    }
}
