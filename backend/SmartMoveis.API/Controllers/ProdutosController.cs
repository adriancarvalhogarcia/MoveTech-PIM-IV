using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Models;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>
/// Consulta de produtos liberada para qualquer usuário autenticado.
/// Cadastro, alteração (inclusive entrada de estoque) e desativação
/// são restritos ao perfil Administrador.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProdutosController : ControllerBase
{
    private readonly IProdutoService _produtos;

    public ProdutosController(IProdutoService produtos)
    {
        _produtos = produtos;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Produto>>> GetProdutos()
    {
        return Ok(await _produtos.ListarAsync());
    }

    [HttpGet("{id}")]
    public async Task<ActionResult> GetProduto(int id)
    {
        return this.ParaResposta(await _produtos.ObterAsync(id));
    }

    [HttpGet("estoque-baixo")]
    public async Task<ActionResult<IEnumerable<Produto>>> GetProdutosComEstoqueBaixo()
    {
        return Ok(await _produtos.ListarEstoqueBaixoAsync());
    }

    [HttpPost]
    [Authorize(Roles = Perfis.Administrador)]
    public async Task<ActionResult> CriarProduto(CriarProdutoDto dto)
    {
        var produto = await _produtos.CriarAsync(dto);

        return CreatedAtAction(
            nameof(GetProduto),
            new { id = produto.Id },
            produto
        );
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Perfis.Administrador)]
    public async Task<ActionResult> AtualizarProduto(
        int id,
        AtualizarProdutoDto dto)
    {
        return this.ParaResposta(await _produtos.AtualizarAsync(id, dto));
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Perfis.Administrador)]
    public async Task<ActionResult> ExcluirProduto(int id)
    {
        return this.ParaResposta(await _produtos.DesativarAsync(id));
    }
}
