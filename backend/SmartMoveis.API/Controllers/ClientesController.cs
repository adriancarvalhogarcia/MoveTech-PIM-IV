using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Models;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>
/// Camada de apresentação: recebe a requisição HTTP, delega a regra
/// de negócio ao <see cref="IClienteService"/> e devolve a resposta.
/// Administradores e vendedores podem cadastrar clientes.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ClientesController : ControllerBase
{
    private readonly IClienteService _clientes;

    public ClientesController(IClienteService clientes)
    {
        _clientes = clientes;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Cliente>>> GetClientes()
    {
        return Ok(await _clientes.ListarAsync());
    }

    [HttpGet("{id}")]
    public async Task<ActionResult> GetCliente(int id)
    {
        return this.ParaResposta(await _clientes.ObterAsync(id));
    }

    [HttpPost]
    public async Task<ActionResult> CriarCliente(CriarClienteDto dto)
    {
        var resultado = await _clientes.CriarAsync(dto);

        if (!resultado.Sucesso)
        {
            return this.ParaFalha(resultado);
        }

        return CreatedAtAction(
            nameof(GetCliente),
            new { id = resultado.Dados!.Id },
            resultado.Dados
        );
    }

    [HttpPut("{id}")]
    public async Task<ActionResult> AtualizarCliente(
        int id,
        AtualizarClienteDto dto)
    {
        return this.ParaResposta(await _clientes.AtualizarAsync(id, dto));
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> ExcluirCliente(int id)
    {
        return this.ParaResposta(await _clientes.DesativarAsync(id));
    }
}
