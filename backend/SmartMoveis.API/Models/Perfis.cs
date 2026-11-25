namespace SmartMoveis.API.Models;

/// <summary>
/// Perfis de acesso do sistema. O valor é gravado na coluna
/// usuarios.Perfil e enviado no token JWT como role.
/// </summary>
public static class Perfis
{
    /// <summary>Acesso total, inclusive usuários, notas de entrada e financeiro.</summary>
    public const string Administrador = "Administrador";

    /// <summary>Atendimento: clientes, consulta de produtos, vendas e devoluções.</summary>
    public const string Funcionario = "Funcionario";

    /// <summary>Expressão usada para validar o perfil recebido pela API.</summary>
    public const string ExpressaoValidos = "^(Administrador|Funcionario)$";
}
