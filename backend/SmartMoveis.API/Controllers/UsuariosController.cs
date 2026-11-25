using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Models;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>
/// Gestão de usuários: área administrativa, restrita ao perfil
/// Administrador. Um funcionário recebe 403 (acesso negado).
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = Perfis.Administrador)]
public class UsuariosController : ControllerBase
{
    private readonly IUsuarioService _usuarios;

    public UsuariosController(IUsuarioService usuarios)
    {
        _usuarios = usuarios;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<UsuarioResposta>>> GetUsuarios()
    {
        return Ok(await _usuarios.ListarAsync());
    }

    [HttpGet("{id}")]
    public async Task<ActionResult> GetUsuario(int id)
    {
        return this.ParaResposta(await _usuarios.ObterAsync(id));
    }

    [HttpPost]
    public async Task<ActionResult> CriarUsuario(CriarUsuarioDto dto)
    {
        var resultado = await _usuarios.CriarAsync(dto);

        if (!resultado.Sucesso)
        {
            return this.ParaFalha(resultado);
        }

        return CreatedAtAction(
            nameof(GetUsuario),
            new { id = resultado.Dados!.Id },
            resultado.Dados
        );
    }

    [HttpPut("{id}")]
    public async Task<ActionResult> AtualizarUsuario(int id, AtualizarUsuarioDto dto)
    {
        return this.ParaResposta(await _usuarios.AtualizarAsync(id, dto));
    }

    [HttpPut("{id}/senha")]
    public async Task<ActionResult> RedefinirSenha(int id, RedefinirSenhaDto dto)
    {
        return this.ParaResposta(await _usuarios.RedefinirSenhaAsync(id, dto));
    }
}
