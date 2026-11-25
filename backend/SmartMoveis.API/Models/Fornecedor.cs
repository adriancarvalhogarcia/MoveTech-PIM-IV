using System.ComponentModel.DataAnnotations;

namespace SmartMoveis.API.Models;

/// <summary>Fornecedor, cadastrado automaticamente a partir do emitente da nota XML.</summary>
public class Fornecedor : EntidadeBase
{
    public int Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string RazaoSocial { get; set; } = string.Empty;

    [MaxLength(150)]
    public string? NomeFantasia { get; set; }

    /// <summary>CNPJ (ou CPF) só com dígitos.</summary>
    [Required]
    [MaxLength(14)]
    public string Documento { get; set; } = string.Empty;

    public bool Ativo { get; set; } = true;

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public override string ObterDescricao()
    {
        return $"{RazaoSocial} - {Documento}";
    }
}

/// <summary>
/// Lembra qual produto do sistema corresponde ao código do produto
/// na nota de um fornecedor, para as próximas importações.
/// </summary>
public class ProdutoFornecedor
{
    public int Id { get; set; }

    public int FornecedorId { get; set; }

    [Required]
    [MaxLength(60)]
    public string CodigoFornecedor { get; set; } = string.Empty;

    public int ProdutoId { get; set; }

    public Fornecedor? Fornecedor { get; set; }

    public Produto? Produto { get; set; }
}
