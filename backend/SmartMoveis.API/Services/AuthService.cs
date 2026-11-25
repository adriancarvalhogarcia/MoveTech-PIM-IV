using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SmartMoveis.API.Data;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

public interface ITokenService
{
    string GerarToken(Usuario usuario);
}

/// <summary>Gera o token JWT com os dados e o perfil (role) do usuário.</summary>
public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;

    public TokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GerarToken(Usuario usuario)
    {
        var jwtKey = _configuration["Jwt:Key"]
            ?? throw new InvalidOperationException("Chave JWT não configurada.");

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new Claim(ClaimTypes.Name, usuario.Nome),
            new Claim(ClaimTypes.Email, usuario.Email),
            new Claim(ClaimTypes.Role, usuario.Perfil)
        };

        var chave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));

        var credenciais = new SigningCredentials(
            chave,
            SecurityAlgorithms.HmacSha256
        );

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(2),
            signingCredentials: credenciais
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

public interface IAuthService
{
    Task<ResultadoServico<object>> LoginAsync(LoginDto dto);
}

/// <summary>Autenticação: confere e-mail, senha (BCrypt) e situação do usuário.</summary>
public class AuthService : IAuthService
{
    private const string MensagemCredenciaisInvalidas = "E-mail ou senha inválidos.";

    private readonly ApplicationDbContext _context;
    private readonly ITokenService _tokens;

    public AuthService(ApplicationDbContext context, ITokenService tokens)
    {
        _context = context;
        _tokens = tokens;
    }

    public async Task<ResultadoServico<object>> LoginAsync(LoginDto dto)
    {
        var email = dto.Email.Trim();

        var usuario = await _context.Usuarios
            .FirstOrDefaultAsync(u => u.Email == email);

        if (usuario == null || !BCrypt.Net.BCrypt.Verify(dto.Senha, usuario.SenhaHash))
        {
            return ResultadoServico<object>.Invalido(MensagemCredenciaisInvalidas);
        }

        if (!usuario.Ativo)
        {
            return ResultadoServico<object>.Invalido("Usuário inativo.");
        }

        return ResultadoServico<object>.Ok(new
        {
            mensagem = "Login realizado com sucesso!",
            token = _tokens.GerarToken(usuario),
            usuario = new
            {
                usuario.Id,
                usuario.Nome,
                usuario.Email,
                usuario.Perfil
            }
        });
    }
}
