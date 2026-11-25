using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartMoveis.API.Models;

/// <summary>
/// Conta a receber ou a pagar. Gerada pelas vendas (receber), pelas
/// notas de entrada (pagar), por reembolsos de devolução (pagar) ou
/// lançada manualmente.
/// </summary>
public class ContaFinanceira
{
    public int Id { get; set; }

    /// <summary>Receber ou Pagar.</summary>
    [Required]
    [MaxLength(10)]
    public string Tipo { get; set; } = TipoConta.Receber;

    [Required]
    [MaxLength(150)]
    public string Descricao { get; set; } = string.Empty;

    /// <summary>Venda, NotaEntrada, Devolucao ou Manual.</summary>
    [Required]
    [MaxLength(20)]
    public string Origem { get; set; } = OrigemConta.Manual;

    public int? VendaId { get; set; }

    public int? NotaEntradaId { get; set; }

    public int? DevolucaoId { get; set; }

    public int? ClienteId { get; set; }

    public int? FornecedorId { get; set; }

    public int NumeroParcela { get; set; } = 1;

    public int TotalParcelas { get; set; } = 1;

    [Column(TypeName = "decimal(12,2)")]
    public decimal Valor { get; set; }

    [Column(TypeName = "date")]
    public DateTime Vencimento { get; set; }

    /// <summary>Aberta, Paga ou Cancelada.</summary>
    [Required]
    [MaxLength(12)]
    public string Status { get; set; } = StatusConta.Aberta;

    [Column(TypeName = "date")]
    public DateTime? DataPagamento { get; set; }

    [Column(TypeName = "decimal(12,2)")]
    public decimal? ValorPago { get; set; }

    [MaxLength(30)]
    public string? FormaPagamento { get; set; }

    [MaxLength(250)]
    public string? Observacao { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public Venda? Venda { get; set; }

    public NotaEntrada? NotaEntrada { get; set; }

    public Cliente? Cliente { get; set; }

    public Fornecedor? Fornecedor { get; set; }

    public List<HistoricoContaFinanceira> Historico { get; set; } = new();
}

/// <summary>Registro de cada baixa, estorno ou cancelamento de uma conta (auditoria).</summary>
public class HistoricoContaFinanceira
{
    public int Id { get; set; }

    public int ContaFinanceiraId { get; set; }

    /// <summary>Criada, Baixada, Estornada, Cancelada ou Ajustada.</summary>
    [Required]
    [MaxLength(20)]
    public string Acao { get; set; } = string.Empty;

    [MaxLength(250)]
    public string? Detalhe { get; set; }

    [MaxLength(100)]
    public string? UsuarioNome { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public ContaFinanceira? ContaFinanceira { get; set; }
}
