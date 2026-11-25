using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartMoveis.API.Models;

public class Produto : EntidadeBase
{
    public int Id { get; set; }

    [Required]
    [MaxLength(120)]
    public string Nome { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Descricao { get; set; }

    [Required]
    [MaxLength(100)]
    public string Categoria { get; set; } = string.Empty;

    [Column(TypeName = "decimal(10,2)")]
    public decimal Preco { get; set; }

    public int QuantidadeEstoque { get; set; }

    public int EstoqueMinimo { get; set; }

    /// <summary>Custo médio ponderado, atualizado a cada nota de entrada.</summary>
    [Column(TypeName = "decimal(12,4)")]
    public decimal CustoMedio { get; set; }

    /// <summary>Código de barras (GTIN/EAN) usado para reconhecer o produto na nota XML.</summary>
    [MaxLength(14)]
    public string? CodigoBarras { get; set; }

    public bool Ativo { get; set; } = true;

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public override string ObterDescricao()
    {
        return $"{Nome} - {Categoria} - R$ {Preco:F2}";
    }
}