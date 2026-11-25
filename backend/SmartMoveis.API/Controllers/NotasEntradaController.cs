using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.DTOs;
using SmartMoveis.API.Models;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>
/// Notas de entrada (importação do XML da NF-e). Restrito ao perfil
/// Administrador, porque mexe em estoque, custo, preços e contas a pagar.
/// </summary>
[ApiController]
[Route("api/notas-entrada")]
[Authorize(Roles = Perfis.Administrador)]
public class NotasEntradaController : ControllerBase
{
    private readonly INotaEntradaService _notas;

    public NotasEntradaController(INotaEntradaService notas)
    {
        _notas = notas;
    }

    [HttpGet]
    public async Task<ActionResult> Listar()
    {
        return Ok(await _notas.ListarAsync());
    }

    [HttpGet("{id}")]
    public async Task<ActionResult> Obter(int id)
    {
        return this.ParaResposta(await _notas.ObterAsync(id));
    }

    /// <summary>Lê o XML e mostra o que será lançado, sem gravar nada.</summary>
    [HttpPost("previa")]
    public async Task<ActionResult> Previa(PreviaNotaDto dto)
    {
        return this.ParaResposta(await _notas.PreviaAsync(dto));
    }

    /// <summary>Lança a nota: estoque, custo médio, produtos novos e contas a pagar.</summary>
    [HttpPost]
    public async Task<ActionResult> Confirmar(ConfirmarNotaDto dto)
    {
        var resultado = await _notas.ConfirmarAsync(dto);
        return resultado.Sucesso
            ? StatusCode(StatusCodes.Status201Created, resultado.Dados)
            : this.ParaFalha(resultado);
    }

    [HttpGet("/api/fornecedores")]
    public async Task<ActionResult> Fornecedores()
    {
        return Ok(await _notas.ListarFornecedoresAsync());
    }
}
