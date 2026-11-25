using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Infraestrutura;
using SmartMoveis.API.Models;

namespace SmartMoveis.API.Services;

/// <summary>Dados públicos do usuário (nunca inclui o hash da senha).</summary>
public record UsuarioResposta(
    int Id,
    string Nome,
    string Email,
    string Perfil,
    bool Ativo,
    DateTime CriadoEm);

public interface IUsuarioService
{
    Task<List<UsuarioResposta>> ListarAsync();
    Task<ResultadoServico<UsuarioResposta>> ObterAsync(int id);
    Task<ResultadoServico<UsuarioResposta>> CriarAsync(CriarUsuarioDto dto);
    Task<ResultadoServico<UsuarioResposta>> AtualizarAsync(int id, AtualizarUsuarioDto dto);
    Task<ResultadoServico<object>> RedefinirSenhaAsync(int id, RedefinirSenhaDto dto);
}

/// <summary>Cadastro de usuários do sistema, com senha protegida por BCrypt.</summary>
public class UsuarioService : IUsuarioService
{
    private readonly ApplicationDbContext _context;
    private readonly IUsuarioAtual _usuarioAtual;

    public UsuarioService(ApplicationDbContext context, IUsuarioAtual usuarioAtual)
    {
        _context = context;
        _usuarioAtual = usuarioAtual;
    }

    public Task<List<UsuarioResposta>> ListarAsync()
    {
        return _context.Usuarios
            .OrderBy(u => u.Nome)
            .Select(u => new UsuarioResposta(
                u.Id, u.Nome, u.Email, u.Perfil, u.Ativo, u.CriadoEm))
            .ToListAsync();
    }

    public async Task<ResultadoServico<UsuarioResposta>> ObterAsync(int id)
    {
        var usuario = await _context.Usuarios
            .Where(u => u.Id == id)
            .Select(u => new UsuarioResposta(
                u.Id, u.Nome, u.Email, u.Perfil, u.Ativo, u.CriadoEm))
            .FirstOrDefaultAsync();

        return usuario == null
            ? ResultadoServico<UsuarioResposta>.NaoEncontrado("Usuário não encontrado.")
            : ResultadoServico<UsuarioResposta>.Ok(usuario);
    }

    public async Task<ResultadoServico<UsuarioResposta>> CriarAsync(CriarUsuarioDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();

        var emailExiste = await _context.Usuarios
            .AnyAsync(u => u.Email == email);

        if (emailExiste)
        {
            return ResultadoServico<UsuarioResposta>.Conflito(
                "Já existe um usuário cadastrado com este e-mail.");
        }

        var usuario = new Usuario
        {
            Nome = dto.Nome.Trim(),
            Email = email,
            SenhaHash = BCrypt.Net.BCrypt.HashPassword(dto.Senha),
            Perfil = dto.Perfil,
            Ativo = true,
            CriadoEm = DateTime.UtcNow
        };

        _context.Usuarios.Add(usuario);
        await _context.SaveChangesAsync();

        return ResultadoServico<UsuarioResposta>.Ok(new UsuarioResposta(
            usuario.Id,
            usuario.Nome,
            usuario.Email,
            usuario.Perfil,
            usuario.Ativo,
            usuario.CriadoEm));
    }

    public async Task<ResultadoServico<UsuarioResposta>> AtualizarAsync(int id, AtualizarUsuarioDto dto)
    {
        var usuario = await _context.Usuarios.FirstOrDefaultAsync(u => u.Id == id);

        if (usuario == null)
        {
            return ResultadoServico<UsuarioResposta>.NaoEncontrado("Usuário não encontrado.");
        }

        var email = dto.Email.Trim().ToLowerInvariant();

        if (await _context.Usuarios.AnyAsync(u => u.Email == email && u.Id != id))
        {
            return ResultadoServico<UsuarioResposta>.Conflito("Já existe outro usuário com este e-mail.");
        }

        var deixaDeSerAdminAtivo =
            usuario.Perfil == Perfis.Administrador && usuario.Ativo &&
            (dto.Perfil != Perfis.Administrador || !dto.Ativo);

        if (deixaDeSerAdminAtivo)
        {
            if (_usuarioAtual.Id == id)
            {
                return ResultadoServico<UsuarioResposta>.Invalido(
                    "Você não pode remover o seu próprio acesso de administrador nem se desativar.");
            }

            var outrosAdmins = await _context.Usuarios.CountAsync(u =>
                u.Id != id && u.Ativo && u.Perfil == Perfis.Administrador);

            if (outrosAdmins == 0)
            {
                return ResultadoServico<UsuarioResposta>.Invalido(
                    "O sistema precisa ter pelo menos um administrador ativo.");
            }
        }

        usuario.Nome = dto.Nome.Trim();
        usuario.Email = email;
        usuario.Perfil = dto.Perfil;
        usuario.Ativo = dto.Ativo;

        await _context.SaveChangesAsync();

        return ResultadoServico<UsuarioResposta>.Ok(new UsuarioResposta(
            usuario.Id, usuario.Nome, usuario.Email, usuario.Perfil, usuario.Ativo, usuario.CriadoEm));
    }

    public async Task<ResultadoServico<object>> RedefinirSenhaAsync(int id, RedefinirSenhaDto dto)
    {
        var usuario = await _context.Usuarios.FirstOrDefaultAsync(u => u.Id == id);

        if (usuario == null)
        {
            return ResultadoServico<object>.NaoEncontrado("Usuário não encontrado.");
        }

        usuario.SenhaHash = BCrypt.Net.BCrypt.HashPassword(dto.NovaSenha);
        await _context.SaveChangesAsync();

        return ResultadoServico<object>.Ok(new { mensagem = $"Senha de {usuario.Nome} redefinida." });
    }
}
