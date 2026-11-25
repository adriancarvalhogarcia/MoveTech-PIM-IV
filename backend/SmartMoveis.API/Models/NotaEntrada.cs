using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartMoveis.API.Models;

/// <summary>Nota fiscal de entrada (compra de mercadoria) importada do XML da NF-e.</summary>
public class NotaEntrada
{
    public int Id { get; set; }

    public int FornecedorId { get; set; }

    [MaxLength(20)]
    public string Numero { get; set; } = string.Empty;

    [MaxLength(5)]
    public string Serie { get; set; } = string.Empty;

    /// <summary>Chave de acesso de 44 dígitos (impede importar a mesma nota duas vezes).</summary>
    [Required]
    [MaxLength(44)]
    public string ChaveAcesso { get; set; } = string.Empty;

    public DateTime DataEmissao { get; set; }

    [Column(TypeName = "decimal(12,2)")]
    public decimal ValorProdutos { get; set; }

    [Column(TypeName = "decimal(12,2)")]
    public decimal ValorTotal { get; set; }

    [Column(TypeName = "decimal(6,2)")]
    public decimal MarkupPercentual { get; set; }

    [MaxLength(100)]
    public string? UsuarioNome { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public Fornecedor? Fornecedor { get; set; }

    public List<ItemNotaEntrada> Itens { get; set; } = new();
}

public class ItemNotaEntrada
{
    public int Id { get; set; }

    public int NotaEntradaId { get; set; }

    public int ProdutoId { get; set; }

    [MaxLength(60)]
    public string CodigoFornecedor { get; set; } = string.Empty;

    [MaxLength(150)]
    public string Descricao { get; set; } = string.Empty;

    public int Quantidade { get; set; }

    /// <summary>Custo unitário com frete, seguro, IPI, ST e outras despesas, menos desconto.</summary>
    [Column(TypeName = "decimal(12,4)")]
    public decimal CustoUnitario { get; set; }

    [Column(TypeName = "decimal(12,2)")]
    public decimal CustoTotal { get; set; }

    /// <summary>True quando o produto foi cadastrado a partir desta nota.</summary>
    public bool ProdutoCriado { get; set; }

    public NotaEntrada? NotaEntrada { get; set; }

    public Produto? Produto { get; set; }
}
