using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>
/// Vendas podem ser registradas por administradores e vendedores.
/// As regras (estoque, valores, baixa) ficam no <see cref="IVendaService"/>.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VendasController : ControllerBase
{
    private readonly IVendaService _vendas;
    private readonly IDevolucaoService _devolucoes;

    public VendasController(IVendaService vendas, IDevolucaoService devolucoes)
    {
        _vendas = vendas;
        _devolucoes = devolucoes;
    }

    [HttpGet]
    public async Task<ActionResult> GetVendas()
    {
        return Ok(await _vendas.ListarAsync());
    }

    [HttpGet("{id}")]
    public async Task<ActionResult> GetVenda(int id)
    {
        return this.ParaResposta(await _vendas.ObterAsync(id));
    }

    [HttpPost]
    public async Task<ActionResult> CriarVenda(CriarVendaDto dto)
    {
        var resultado = await _vendas.CriarAsync(dto);

        if (!resultado.Sucesso)
        {
            return this.ParaFalha(resultado);
        }

        return CreatedAtAction(
            nameof(GetVenda),
            new { id = resultado.Dados!.Id },
            resultado.Dados.Resposta
        );
    }

    /// <summary>Devolução total ou parcial da venda.</summary>
    [HttpPost("{id}/devolucoes")]
    public async Task<ActionResult> Devolver(int id, CriarDevolucaoDto dto)
    {
        return this.ParaResposta(await _devolucoes.CriarAsync(id, dto));
    }

    /// <summary>Todas as devoluções registradas.</summary>
    [HttpGet("devolucoes")]
    public async Task<ActionResult> ListarDevolucoes()
    {
        return Ok(await _devolucoes.ListarAsync());
    }
}
