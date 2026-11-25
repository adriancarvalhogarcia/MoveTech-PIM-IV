using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Models;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>Contas a pagar e a receber. Restrito ao perfil Administrador.</summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = Perfis.Administrador)]
public class FinanceiroController : ControllerBase
{
    private readonly IFinanceiroService _financeiro;

    public FinanceiroController(IFinanceiroService financeiro)
    {
        _financeiro = financeiro;
    }

    /// <summary>Lista com filtros: ?tipo=Receber&amp;status=Vencida&amp;de=2026-10-01&amp;ate=2026-10-31&amp;busca=ana</summary>
    [HttpGet]
    public async Task<ActionResult> Listar([FromQuery] FiltroContasDto filtro)
    {
        return Ok(await _financeiro.ListarAsync(filtro));
    }

    [HttpGet("resumo")]
    public async Task<ActionResult> Resumo()
    {
        return Ok(await _financeiro.ResumoAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult> Obter(int id)
    {
        return this.ParaResposta(await _financeiro.ObterAsync(id));
    }

    [HttpPost]
    public async Task<ActionResult> Lancar(CriarContaDto dto)
    {
        var resultado = await _financeiro.CriarManualAsync(dto);
        return resultado.Sucesso
            ? StatusCode(StatusCodes.Status201Created, resultado.Dados)
            : this.ParaFalha(resultado);
    }

    [HttpPost("{id:int}/baixar")]
    public async Task<ActionResult> Baixar(int id, BaixarContaDto dto)
    {
        return this.ParaResposta(await _financeiro.BaixarAsync(id, dto));
    }

    [HttpPost("{id:int}/estornar")]
    public async Task<ActionResult> Estornar(int id, MotivoDto dto)
    {
        return this.ParaResposta(await _financeiro.EstornarAsync(id, dto));
    }

    [HttpPost("{id:int}/cancelar")]
    public async Task<ActionResult> Cancelar(int id, MotivoDto dto)
    {
        return this.ParaResposta(await _financeiro.CancelarAsync(id, dto));
    }
}
