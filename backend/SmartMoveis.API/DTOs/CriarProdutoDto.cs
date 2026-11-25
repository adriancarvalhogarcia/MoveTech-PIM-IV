using System.ComponentModel.DataAnnotations;

namespace SmartMoveis.API.DTOs;

public class CriarProdutoDto
{
    [Required(ErrorMessage = "O campo Nome é obrigatório.")]
    [MaxLength(120, ErrorMessage = "O campo Nome deve ter no máximo 120 caracteres.")]
    public string Nome { get; set; } = string.Empty;

    [MaxLength(500, ErrorMessage = "O campo Descrição deve ter no máximo 500 caracteres.")]
    public string? Descricao { get; set; }

    [Required(ErrorMessage = "O campo Categoria é obrigatório.")]
    [MaxLength(100, ErrorMessage = "O campo Categoria deve ter no máximo 100 caracteres.")]
    public string Categoria { get; set; } = string.Empty;

    [Range(0.01, double.MaxValue, ErrorMessage = "O preço deve ser maior que zero.")]
    public decimal Preco { get; set; }

    [Range(0, int.MaxValue, ErrorMessage = "A quantidade em estoque não pode ser negativa.")]
    public int QuantidadeEstoque { get; set; }

    [Range(0, int.MaxValue, ErrorMessage = "O estoque mínimo não pode ser negativo.")]
    public int EstoqueMinimo { get; set; }

    [MaxLength(14, ErrorMessage = "O campo Código de barras deve ter no máximo 14 caracteres.")]
    [RegularExpression("^[0-9]{8,14}$", ErrorMessage = "Código de barras deve ter de 8 a 14 dígitos.")]
    public string? CodigoBarras { get; set; }
}