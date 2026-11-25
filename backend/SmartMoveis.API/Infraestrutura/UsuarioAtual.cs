using System.Security.Claims;

namespace SmartMoveis.API.Infraestrutura;

public interface IUsuarioAtual
{
    int? Id { get; }
    string Nome { get; }
    bool Administrador { get; }
}

/// <summary>Dados do usuário logado, lidos do token JWT da requisição.</summary>
public class UsuarioAtual : IUsuarioAtual
{
    private readonly IHttpContextAccessor _acessor;

    public UsuarioAtual(IHttpContextAccessor acessor)
    {
        _acessor = acessor;
    }

    private ClaimsPrincipal? Usuario => _acessor.HttpContext?.User;

    public int? Id =>
        int.TryParse(Usuario?.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;

    public string Nome => Usuario?.FindFirstValue(ClaimTypes.Name) ?? "Sistema";

    public bool Administrador => Usuario?.IsInRole(Models.Perfis.Administrador) ?? false;
}
