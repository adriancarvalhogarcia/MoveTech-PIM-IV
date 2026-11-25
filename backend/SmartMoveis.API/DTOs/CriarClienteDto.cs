using System.ComponentModel.DataAnnotations;
using SmartMoveis.API.Validacoes;

namespace SmartMoveis.API.DTOs;

public class CriarClienteDto
{
    [Required(ErrorMessage = "O campo Nome é obrigatório.")]
    [MaxLength(120, ErrorMessage = "O campo Nome deve ter no máximo 120 caracteres.")]
    public string Nome { get; set; } = string.Empty;

    [Required(ErrorMessage = "Informe o CPF.")]
    [MaxLength(14, ErrorMessage = "O campo CPF deve ter no máximo 14 caracteres.")]
    [Cpf]
    public string CPF { get; set; } = string.Empty;

    [MaxLength(20, ErrorMessage = "O campo Telefone deve ter no máximo 20 caracteres.")]
    public string? Telefone { get; set; }

    [EmailAddress(ErrorMessage = "E-mail inválido.")]
    [MaxLength(150, ErrorMessage = "O campo E-mail deve ter no máximo 150 caracteres.")]
    public string? Email { get; set; }

    [MaxLength(250, ErrorMessage = "O campo Endereço deve ter no máximo 250 caracteres.")]
    public string? Endereco { get; set; }
}