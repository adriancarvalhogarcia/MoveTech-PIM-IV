using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Infraestrutura;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

public interface IFinanceiroService
{
    Task<List<object>> ListarAsync(FiltroContasDto filtro);
    Task<ResultadoServico<object>> ObterAsync(int id);
    Task<object> ResumoAsync();
    Task<ResultadoServico<object>> CriarManualAsync(CriarContaDto dto);
    Task<ResultadoServico<object>> BaixarAsync(int id, BaixarContaDto dto);
    Task<ResultadoServico<object>> EstornarAsync(int id, MotivoDto dto);
    Task<ResultadoServico<object>> CancelarAsync(int id, MotivoDto dto);
}

/// <summary>
/// Contas a pagar e a receber: listagem, resumo, baixa (pagamento ou
/// recebimento), estorno da baixa, lançamento manual e cancelamento.
/// Toda alteração fica registrada no histórico da conta.
/// </summary>
public class FinanceiroService : IFinanceiroService
{
    private readonly ApplicationDbContext _context;
    private readonly IUsuarioAtual _usuario;

    public FinanceiroService(ApplicationDbContext context, IUsuarioAtual usuario)
    {
        _context = context;
        _usuario = usuario;
    }

    // =========================================================
    // GERAÇÃO DE CONTAS (usada por vendas, notas e devoluções)
    // =========================================================

    /// <summary>
    /// Cria as parcelas de uma conta. As parcelas vencem de 30 em 30 dias
    /// a partir de <paramref name="primeiroVencimento"/>.
    /// </summary>
    public static List<ContaFinanceira> GerarParcelas(
        ContaFinanceira modelo,
        decimal total,
        int parcelas,
        DateTime primeiroVencimento,
        string usuarioNome)
    {
        var valores = Parcelamento.Dividir(total, parcelas);
        var contas = new List<ContaFinanceira>();

        // A coluna tem 150 caracteres; sobra espaço para o " (12/12)".
        var descricaoBase = modelo.Descricao.Length > 140
            ? modelo.Descricao[..140]
            : modelo.Descricao;

        for (var i = 0; i < valores.Count; i++)
        {
            var conta = new ContaFinanceira
            {
                Tipo = modelo.Tipo,
                Origem = modelo.Origem,
                Descricao = parcelas > 1
                    ? $"{descricaoBase} ({i + 1}/{parcelas})"
                    : descricaoBase,
                VendaId = modelo.VendaId,
                NotaEntradaId = modelo.NotaEntradaId,
                DevolucaoId = modelo.DevolucaoId,
                ClienteId = modelo.ClienteId,
                FornecedorId = modelo.FornecedorId,
                Venda = modelo.Venda,
                NotaEntrada = modelo.NotaEntrada,
                NumeroParcela = i + 1,
                TotalParcelas = parcelas,
                Valor = valores[i],
                Vencimento = primeiroVencimento.Date.AddMonths(i),
                Status = StatusConta.Aberta,
                Observacao = modelo.Observacao,
                CriadoEm = DateTime.UtcNow
            };

            conta.Historico.Add(new HistoricoContaFinanceira
            {
                Acao = "Criada",
                Detalhe = $"Origem: {modelo.Origem}",
                UsuarioNome = usuarioNome
            });

            contas.Add(conta);
        }

        return contas;
    }

    /// <summary>Marca a conta como paga e registra no histórico.</summary>
    public static void AplicarBaixa(
        ContaFinanceira conta,
        DateTime data,
        string forma,
        decimal valorPago,
        string? observacao,
        string usuarioNome)
    {
        conta.Status = StatusConta.Paga;
        conta.DataPagamento = data.Date;
        conta.FormaPagamento = forma;
        conta.ValorPago = valorPago;

        if (!string.IsNullOrWhiteSpace(observacao))
        {
            conta.Observacao = observacao;
        }

        conta.Historico.Add(new HistoricoContaFinanceira
        {
            Acao = "Baixada",
            Detalhe = $"{forma} - R$ {valorPago:N2} em {data:dd/MM/yyyy}",
            UsuarioNome = usuarioNome
        });
    }

    // =========================================================
    // CONSULTAS
    // =========================================================

    public async Task<List<object>> ListarAsync(FiltroContasDto filtro)
    {
        var hoje = DateTime.Today;
        var consulta = _context.ContasFinanceiras.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(filtro.Tipo))
        {
            consulta = consulta.Where(c => c.Tipo == filtro.Tipo);
        }

        if (filtro.Status == "Vencida")
        {
            consulta = consulta.Where(c => c.Status == StatusConta.Aberta && c.Vencimento < hoje);
        }
        else if (!string.IsNullOrWhiteSpace(filtro.Status))
        {
            consulta = consulta.Where(c => c.Status == filtro.Status);
        }

        if (filtro.De.HasValue)
        {
            consulta = consulta.Where(c => c.Vencimento >= filtro.De.Value.Date);
        }

        if (filtro.Ate.HasValue)
        {
            consulta = consulta.Where(c => c.Vencimento <= filtro.Ate.Value.Date);
        }

        if (filtro.VendaId.HasValue)
        {
            consulta = consulta.Where(c => c.VendaId == filtro.VendaId);
        }

        if (filtro.NotaEntradaId.HasValue)
        {
            consulta = consulta.Where(c => c.NotaEntradaId == filtro.NotaEntradaId);
        }

        if (!string.IsNullOrWhiteSpace(filtro.Busca))
        {
            var termo = filtro.Busca.Trim();
            consulta = consulta.Where(c =>
                c.Descricao.Contains(termo) ||
                (c.Cliente != null && c.Cliente.Nome.Contains(termo)) ||
                (c.Fornecedor != null && c.Fornecedor.RazaoSocial.Contains(termo)));
        }

        var contas = await consulta
            .OrderBy(c => c.Status == StatusConta.Aberta ? 0 : 1)
            .ThenBy(c => c.Vencimento)
            .ThenBy(c => c.Id)
            .Select(c => new
            {
                c.Id,
                c.Tipo,
                c.Descricao,
                c.Origem,
                c.VendaId,
                c.NotaEntradaId,
                c.DevolucaoId,
                c.ClienteId,
                Cliente = c.Cliente != null ? c.Cliente.Nome : null,
                c.FornecedorId,
                Fornecedor = c.Fornecedor != null ? c.Fornecedor.RazaoSocial : null,
                c.NumeroParcela,
                c.TotalParcelas,
                c.Valor,
                c.Vencimento,
                c.Status,
                Vencida = c.Status == StatusConta.Aberta && c.Vencimento < hoje,
                c.DataPagamento,
                c.ValorPago,
                c.FormaPagamento,
                c.Observacao
            })
            .Take(500)
            .ToListAsync();

        return contas.Cast<object>().ToList();
    }

    public async Task<ResultadoServico<object>> ObterAsync(int id)
    {
        var conta = await _context.ContasFinanceiras
            .AsNoTracking()
            .Where(c => c.Id == id)
            .Select(c => new
            {
                c.Id,
                c.Tipo,
                c.Descricao,
                c.Origem,
                c.VendaId,
                c.NotaEntradaId,
                c.DevolucaoId,
                Cliente = c.Cliente != null ? c.Cliente.Nome : null,
                Fornecedor = c.Fornecedor != null ? c.Fornecedor.RazaoSocial : null,
                c.NumeroParcela,
                c.TotalParcelas,
                c.Valor,
                c.Vencimento,
                c.Status,
                c.DataPagamento,
                c.ValorPago,
                c.FormaPagamento,
                c.Observacao,
                Historico = c.Historico
                    .OrderBy(h => h.CriadoEm)
                    .Select(h => new { h.Acao, h.Detalhe, h.UsuarioNome, h.CriadoEm })
            })
            .FirstOrDefaultAsync();

        return conta == null
            ? ResultadoServico<object>.NaoEncontrado("Conta não encontrada.")
            : ResultadoServico<object>.Ok(conta);
    }

    public async Task<object> ResumoAsync()
    {
        var hoje = DateTime.Today;
        var inicioMes = new DateTime(hoje.Year, hoje.Month, 1);
        var fimMes = inicioMes.AddMonths(1);

        var abertas = _context.ContasFinanceiras.Where(c => c.Status == StatusConta.Aberta);
        var pagasNoMes = _context.ContasFinanceiras.Where(c =>
            c.Status == StatusConta.Paga &&
            c.DataPagamento >= inicioMes && c.DataPagamento < fimMes);

        var aReceber = await abertas.Where(c => c.Tipo == TipoConta.Receber).SumAsync(c => (decimal?)c.Valor) ?? 0;
        var aPagar = await abertas.Where(c => c.Tipo == TipoConta.Pagar).SumAsync(c => (decimal?)c.Valor) ?? 0;
        var receberVencido = await abertas.Where(c => c.Tipo == TipoConta.Receber && c.Vencimento < hoje).SumAsync(c => (decimal?)c.Valor) ?? 0;
        var pagarVencido = await abertas.Where(c => c.Tipo == TipoConta.Pagar && c.Vencimento < hoje).SumAsync(c => (decimal?)c.Valor) ?? 0;
        var recebidoMes = await pagasNoMes.Where(c => c.Tipo == TipoConta.Receber).SumAsync(c => c.ValorPago ?? c.Valor);
        var pagoMes = await pagasNoMes.Where(c => c.Tipo == TipoConta.Pagar).SumAsync(c => c.ValorPago ?? c.Valor);

        return new
        {
            aReceber,
            aPagar,
            receberVencido,
            pagarVencido,
            recebidoMes,
            pagoMes,
            saldoPrevisto = aReceber - aPagar
        };
    }

    // =========================================================
    // OPERAÇÕES
    // =========================================================

    public async Task<ResultadoServico<object>> CriarManualAsync(CriarContaDto dto)
    {
        if (dto.ClienteId.HasValue && !await _context.Clientes.AnyAsync(c => c.Id == dto.ClienteId))
        {
            return ResultadoServico<object>.Invalido("Cliente não encontrado.");
        }

        if (dto.FornecedorId.HasValue && !await _context.Fornecedores.AnyAsync(f => f.Id == dto.FornecedorId))
        {
            return ResultadoServico<object>.Invalido("Fornecedor não encontrado.");
        }

        var contas = GerarParcelas(
            new ContaFinanceira
            {
                Tipo = dto.Tipo,
                Origem = OrigemConta.Manual,
                Descricao = dto.Descricao.Trim(),
                ClienteId = dto.ClienteId,
                FornecedorId = dto.FornecedorId,
                Observacao = dto.Observacao
            },
            dto.Valor,
            dto.Parcelas,
            dto.Vencimento,
            _usuario.Nome);

        _context.ContasFinanceiras.AddRange(contas);
        await _context.SaveChangesAsync();

        return ResultadoServico<object>.Ok(new
        {
            mensagem = contas.Count > 1
                ? $"{contas.Count} parcelas lançadas."
                : "Conta lançada.",
            ids = contas.Select(c => c.Id)
        });
    }

    public async Task<ResultadoServico<object>> BaixarAsync(int id, BaixarContaDto dto)
    {
        var conta = await _context.ContasFinanceiras.FirstOrDefaultAsync(c => c.Id == id);

        if (conta == null)
        {
            return ResultadoServico<object>.NaoEncontrado("Conta não encontrada.");
        }

        if (conta.Status != StatusConta.Aberta)
        {
            return ResultadoServico<object>.Conflito(
                conta.Status == StatusConta.Paga
                    ? "Esta conta já está baixada. Estorne a baixa antes, se precisar refazer."
                    : "Conta cancelada não pode ser baixada.");
        }

        var data = (dto.DataPagamento ?? DateTime.Today).Date;

        if (data > DateTime.Today)
        {
            return ResultadoServico<object>.Invalido("A data do pagamento não pode ser futura.");
        }

        AplicarBaixa(conta, data, dto.FormaPagamento, dto.ValorPago ?? conta.Valor, dto.Observacao, _usuario.Nome);

        await _context.SaveChangesAsync();

        return ResultadoServico<object>.Ok(new
        {
            mensagem = conta.Tipo == TipoConta.Receber
                ? "Recebimento registrado."
                : "Pagamento registrado.",
            conta.Id,
            conta.Status
        });
    }

    public async Task<ResultadoServico<object>> EstornarAsync(int id, MotivoDto dto)
    {
        var conta = await _context.ContasFinanceiras.FirstOrDefaultAsync(c => c.Id == id);

        if (conta == null)
        {
            return ResultadoServico<object>.NaoEncontrado("Conta não encontrada.");
        }

        if (conta.Status != StatusConta.Paga)
        {
            return ResultadoServico<object>.Conflito("Só é possível estornar uma conta baixada.");
        }

        var detalhe = $"Estorno de {conta.FormaPagamento} R$ {conta.ValorPago:N2} " +
                      $"({conta.DataPagamento:dd/MM/yyyy}). Motivo: {dto.Motivo.Trim()}";

        conta.Status = StatusConta.Aberta;
        conta.DataPagamento = null;
        conta.ValorPago = null;
        conta.FormaPagamento = null;

        _context.HistoricoContasFinanceiras.Add(new HistoricoContaFinanceira
        {
            ContaFinanceiraId = conta.Id,
            Acao = "Estornada",
            Detalhe = detalhe.Length > 250 ? detalhe[..250] : detalhe,
            UsuarioNome = _usuario.Nome
        });

        await _context.SaveChangesAsync();

        return ResultadoServico<object>.Ok(new
        {
            mensagem = "Baixa estornada. A conta voltou a ficar em aberto.",
            conta.Id,
            conta.Status
        });
    }

    public async Task<ResultadoServico<object>> CancelarAsync(int id, MotivoDto dto)
    {
        var conta = await _context.ContasFinanceiras.FirstOrDefaultAsync(c => c.Id == id);

        if (conta == null)
        {
            return ResultadoServico<object>.NaoEncontrado("Conta não encontrada.");
        }

        if (conta.Origem != OrigemConta.Manual)
        {
            return ResultadoServico<object>.Conflito(
                "Só contas lançadas manualmente podem ser canceladas. " +
                "As contas de vendas são ajustadas pela devolução; as de notas e reembolsos são baixadas normalmente.");
        }

        if (conta.Status != StatusConta.Aberta)
        {
            return ResultadoServico<object>.Conflito("Só é possível cancelar uma conta em aberto.");
        }

        conta.Status = StatusConta.Cancelada;

        _context.HistoricoContasFinanceiras.Add(new HistoricoContaFinanceira
        {
            ContaFinanceiraId = conta.Id,
            Acao = "Cancelada",
            Detalhe = dto.Motivo.Trim(),
            UsuarioNome = _usuario.Nome
        });

        await _context.SaveChangesAsync();

        return ResultadoServico<object>.Ok(new { mensagem = "Conta cancelada.", conta.Id, conta.Status });
    }
}
