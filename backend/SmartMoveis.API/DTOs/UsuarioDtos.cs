using System.ComponentModel.DataAnnotations;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.DTOs;

public class AtualizarUsuarioDto
{
    [Required(ErrorMessage = "Informe o nome.")]
    [MaxLength(100, ErrorMessage = "O campo Nome deve ter no máximo 100 caracteres.")]
    public string Nome { get; set; } = string.Empty;

    [Required(ErrorMessage = "Informe o e-mail.")]
    [EmailAddress(ErrorMessage = "E-mail inválido.")]
    [MaxLength(150, ErrorMessage = "O campo E-mail deve ter no máximo 150 caracteres.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "O campo Perfil é obrigatório.")]
    [RegularExpression(Perfis.ExpressaoValidos, ErrorMessage = "Perfil deve ser Administrador ou Funcionario.")]
    public string Perfil { get; set; } = Perfis.Funcionario;

    public bool Ativo { get; set; } = true;
}

public class RedefinirSenhaDto
{
    [Required(ErrorMessage = "Informe a nova senha.")]
    [MinLength(6, ErrorMessage = "A senha deve ter pelo menos 6 caracteres.")]
    [MaxLength(100, ErrorMessage = "O campo Nova senha deve ter no máximo 100 caracteres.")]
    public string NovaSenha { get; set; } = string.Empty;
}
