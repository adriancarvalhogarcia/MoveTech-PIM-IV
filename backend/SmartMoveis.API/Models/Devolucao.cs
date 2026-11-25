using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartMoveis.API.Models;

/// <summary>Devolução total ou parcial de uma venda.</summary>
public class Devolucao
{
    public int Id { get; set; }

    public int VendaId { get; set; }

    [MaxLength(250)]
    public string Motivo { get; set; } = string.Empty;

    [Column(TypeName = "decimal(10,2)")]
    public decimal ValorTotal { get; set; }

    [MaxLength(100)]
    public string? UsuarioNome { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public Venda? Venda { get; set; }

    public List<ItemDevolucao> Itens { get; set; } = new();
}

public class ItemDevolucao
{
    public int Id { get; set; }

    public int DevolucaoId { get; set; }

    public int ItemVendaId { get; set; }

    public int ProdutoId { get; set; }

    public int Quantidade { get; set; }

    [Column(TypeName = "decimal(10,2)")]
    public decimal PrecoUnitario { get; set; }

    [Column(TypeName = "decimal(10,2)")]
    public decimal Subtotal { get; set; }

    public Devolucao? Devolucao { get; set; }

    public ItemVenda? ItemVenda { get; set; }

    public Produto? Produto { get; set; }
}
