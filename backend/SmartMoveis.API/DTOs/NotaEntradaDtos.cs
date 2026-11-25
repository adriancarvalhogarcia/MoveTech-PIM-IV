using System.ComponentModel.DataAnnotations;

namespace SmartMoveis.API.DTOs;

public class PreviaNotaDto
{
    /// <summary>Conteúdo do arquivo XML da NF-e.</summary>
    [Required(ErrorMessage = "Envie o conteúdo do XML da nota.")]
    [MaxLength(10_000_000)]
    public string Xml { get; set; } = string.Empty;

    /// <summary>Margem sobre o custo para sugerir o preço dos produtos novos.</summary>
    [Range(0, 1000, ErrorMessage = "O markup deve estar entre 0% e 1000%.")]
    public decimal MarkupPercentual { get; set; } = 80;
}

public class ConfirmarNotaDto : PreviaNotaDto
{
    /// <summary>
    /// Decisão para cada item da nota. Item não informado segue a sugestão
    /// da prévia: vincula ao produto reconhecido ou cadastra um novo.
    /// </summary>
    public List<DecisaoItemNotaDto> Itens { get; set; } = new();

    /// <summary>
    /// Usado só quando a nota não traz duplicatas (cobr/dup): vencimento
    /// da primeira parcela. Padrão: 30 dias após a emissão.
    /// </summary>
    public DateTime? PrimeiroVencimento { get; set; }

    [Range(1, 24, ErrorMessage = "Parcelas devem estar entre 1 e 24.")]
    public int Parcelas { get; set; } = 1;
}

public class DecisaoItemNotaDto
{
    /// <summary>nItem da nota.</summary>
    public int NumeroItem { get; set; }

    /// <summary>"vincular" (produto existente) ou "criar" (novo produto).</summary>
    [Required(ErrorMessage = "O campo Acao é obrigatório.")]
    [RegularExpression("^(vincular|criar)$", ErrorMessage = "Ação deve ser vincular ou criar.")]
    public string Acao { get; set; } = "criar";

    /// <summary>Obrigatório quando a ação é vincular.</summary>
    public int? ProdutoId { get; set; }

    [MaxLength(120, ErrorMessage = "O campo Nome deve ter no máximo 120 caracteres.")]
    public string? Nome { get; set; }

    [MaxLength(100, ErrorMessage = "O campo Categoria deve ter no máximo 100 caracteres.")]
    public string? Categoria { get; set; }

    [Range(0.01, 99999999, ErrorMessage = "O preço de venda deve ser maior que zero.")]
    public decimal? PrecoVenda { get; set; }

    [Range(0, int.MaxValue, ErrorMessage = "O estoque mínimo não pode ser negativo.")]
    public int? EstoqueMinimo { get; set; }
}
