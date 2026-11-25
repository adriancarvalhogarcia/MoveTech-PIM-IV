using System.ComponentModel.DataAnnotations;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.DTOs;

public class CriarUsuarioDto
{
    [Required(ErrorMessage = "O campo Nome é obrigatório.")]
    [MaxLength(100, ErrorMessage = "O campo Nome deve ter no máximo 100 caracteres.")]
    public string Nome { get; set; } = string.Empty;

    [Required(ErrorMessage = "O campo E-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "E-mail inválido.")]
    [MaxLength(150, ErrorMessage = "O campo E-mail deve ter no máximo 150 caracteres.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "O campo Senha é obrigatório.")]
    [MinLength(6, ErrorMessage = "A senha deve ter pelo menos 6 caracteres.")]
    public string Senha { get; set; } = string.Empty;

    [Required(ErrorMessage = "O campo Perfil é obrigatório.")]
    [MaxLength(30, ErrorMessage = "O campo Perfil deve ter no máximo 30 caracteres.")]
    [RegularExpression(Perfis.ExpressaoValidos, ErrorMessage = "Perfil deve ser Administrador ou Funcionario.")]
    public string Perfil { get; set; } = Perfis.Funcionario;
}