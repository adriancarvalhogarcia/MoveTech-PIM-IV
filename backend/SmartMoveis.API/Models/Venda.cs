using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartMoveis.API.Models;

public class Venda
{
    public int Id { get; set; }

    [Required]
    public int ClienteId { get; set; }

    [Column(TypeName = "decimal(10,2)")]
    public decimal ValorTotal { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    /// <summary>Dinheiro, Pix, CartaoDebito, CartaoCredito, Boleto ou Crediario.</summary>
    [MaxLength(30)]
    public string FormaPagamento { get; set; } = FormasPagamento.NaoInformada;

    public int Parcelas { get; set; } = 1;

    [Column(TypeName = "decimal(10,2)")]
    public decimal ValorDevolvido { get; set; }

    /// <summary>Concluida, DevolvidaParcial ou Devolvida.</summary>
    [MaxLength(20)]
    public string Status { get; set; } = StatusVenda.Concluida;

    public List<Devolucao> Devolucoes { get; set; } = new();

    public Cliente? Cliente { get; set; }

    public List<ItemVenda> Itens { get; set; } = new();
}