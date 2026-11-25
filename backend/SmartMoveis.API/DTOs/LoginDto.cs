using System.ComponentModel.DataAnnotations;

namespace SmartMoveis.API.DTOs;

public class LoginDto
{
    [Required(ErrorMessage = "O campo E-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "E-mail inválido.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "O campo Senha é obrigatório.")]
    public string Senha { get; set; } = string.Empty;
}