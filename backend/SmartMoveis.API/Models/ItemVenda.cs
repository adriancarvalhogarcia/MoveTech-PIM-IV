using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartMoveis.API.Models;

public class ItemVenda
{
    public int Id { get; set; }

    [Required]
    public int VendaId { get; set; }

    [Required]
    public int ProdutoId { get; set; }

    [Required]
    [Range(1, int.MaxValue)]
    public int Quantidade { get; set; }

    [Required]
    [Column(TypeName = "decimal(10,2)")]
    public decimal PrecoUnitario { get; set; }

    [Required]
    [Column(TypeName = "decimal(10,2)")]
    public decimal Subtotal { get; set; }

    /// <summary>Quanto deste item já foi devolvido.</summary>
    public int QuantidadeDevolvida { get; set; }

    public Venda? Venda { get; set; }

    public Produto? Produto { get; set; }
}
