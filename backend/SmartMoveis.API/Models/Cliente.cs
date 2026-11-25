using System.ComponentModel.DataAnnotations;

namespace SmartMoveis.API.Models;

public class Cliente : EntidadeBase
{
    public int Id { get; set; }

    [Required]
    [MaxLength(120)]
    public string Nome { get; set; } = string.Empty;

    [Required]
    [MaxLength(14)]
    public string CPF { get; set; } = string.Empty;

    [MaxLength(20)]
    public string? Telefone { get; set; }

    [EmailAddress]
    [MaxLength(150)]
    public string? Email { get; set; }

    [MaxLength(250)]
    public string? Endereco { get; set; }

    public bool Ativo { get; set; } = true;

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public override string ObterDescricao()
    {
        return $"{Nome} - CPF: {CPF}";
    }
}