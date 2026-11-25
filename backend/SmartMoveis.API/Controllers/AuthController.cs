using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>Login (único endpoint público da API).</summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;

    public AuthController(IAuthService auth)
    {
        _auth = auth;
    }

    [HttpPost("login")]
    public async Task<ActionResult> Login(LoginDto dto)
    {
        var resultado = await _auth.LoginAsync(dto);

        // Falha de login sempre responde 401, como antes.
        return resultado.Sucesso
            ? Ok(resultado.Dados)
            : Unauthorized(resultado.Erro);
    }
}
