using System.ComponentModel.DataAnnotations;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.DTOs;

public class BaixarContaDto
{
    /// <summary>Data do pagamento/recebimento. Se não informada, usa hoje.</summary>
    public DateTime? DataPagamento { get; set; }

    [Required(ErrorMessage = "Informe a forma de pagamento.")]
    [RegularExpression(FormasPagamento.ExpressaoBaixa, ErrorMessage = "Forma de pagamento inválida.")]
    public string FormaPagamento { get; set; } = string.Empty;

    /// <summary>Valor efetivamente pago (com juros ou desconto). Se não informado, usa o valor da conta.</summary>
    [Range(0.01, 99999999, ErrorMessage = "O valor pago deve ser maior que zero.")]
    public decimal? ValorPago { get; set; }

    [MaxLength(250, ErrorMessage = "O campo Observação deve ter no máximo 250 caracteres.")]
    public string? Observacao { get; set; }
}

public class MotivoDto
{
    [Required(ErrorMessage = "Informe o motivo.")]
    [MinLength(3, ErrorMessage = "Descreva o motivo com pelo menos 3 caracteres.")]
    [MaxLength(250, ErrorMessage = "O campo Motivo deve ter no máximo 250 caracteres.")]
    public string Motivo { get; set; } = string.Empty;
}

public class CriarContaDto
{
    [Required(ErrorMessage = "O campo Tipo é obrigatório.")]
    [RegularExpression("^(Receber|Pagar)$", ErrorMessage = "Tipo deve ser Receber ou Pagar.")]
    public string Tipo { get; set; } = TipoConta.Pagar;

    [Required(ErrorMessage = "Informe a descrição.")]
    [MaxLength(150, ErrorMessage = "O campo Descrição deve ter no máximo 150 caracteres.")]
    public string Descricao { get; set; } = string.Empty;

    [Range(0.01, 99999999, ErrorMessage = "O valor deve ser maior que zero.")]
    public decimal Valor { get; set; }

    [Required(ErrorMessage = "Informe o vencimento.")]
    public DateTime Vencimento { get; set; }

    /// <summary>Divide o valor em parcelas mensais a partir do vencimento.</summary>
    [Range(1, 24, ErrorMessage = "Parcelas devem estar entre 1 e 24.")]
    public int Parcelas { get; set; } = 1;

    public int? ClienteId { get; set; }

    public int? FornecedorId { get; set; }

    [MaxLength(250, ErrorMessage = "O campo Observação deve ter no máximo 250 caracteres.")]
    public string? Observacao { get; set; }
}

/// <summary>Filtros da listagem do financeiro (todos opcionais).</summary>
public class FiltroContasDto
{
    /// <summary>Receber ou Pagar.</summary>
    public string? Tipo { get; set; }

    /// <summary>Aberta, Paga, Cancelada ou Vencida.</summary>
    public string? Status { get; set; }

    /// <summary>Vencimento a partir de.</summary>
    public DateTime? De { get; set; }

    /// <summary>Vencimento até.</summary>
    public DateTime? Ate { get; set; }

    /// <summary>Texto na descrição, cliente ou fornecedor.</summary>
    public string? Busca { get; set; }

    public int? VendaId { get; set; }

    public int? NotaEntradaId { get; set; }
}
