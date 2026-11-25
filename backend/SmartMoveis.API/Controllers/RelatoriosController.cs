using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartMoveis.API.Services;

namespace SmartMoveis.API.Controllers;

/// <summary>
/// Relatórios e dashboard. Os cálculos ficam no <see cref="IRelatorioService"/>.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RelatoriosController : ControllerBase
{
    private readonly IRelatorioService _relatorios;
    private readonly IBancoProgramadoService _banco;

    public RelatoriosController(IRelatorioService relatorios, IBancoProgramadoService banco)
    {
        _relatorios = relatorios;
        _banco = banco;
    }

    [HttpGet("dashboard")]
    public async Task<ActionResult> GetDashboard()
    {
        return Ok(await _relatorios.ObterDashboardAsync());
    }

    [HttpGet("analise-inteligente")]
    public async Task<ActionResult> GetAnaliseInteligente()
    {
        return this.ParaResposta(await _relatorios.ObterAnaliseInteligenteAsync());
    }

    // =========================================================
    // Relatórios calculados por STORED PROCEDURES no MySQL
    // =========================================================

    /// <summary>Resumo de vendas do período (procedure sp_resumo_vendas_periodo).</summary>
    [HttpGet("banco/resumo-vendas")]
    public async Task<ActionResult> GetResumoVendas([FromQuery] DateTime? inicio, [FromQuery] DateTime? fim)
    {
        return this.ParaResposta(await _banco.ResumoVendasPeriodoAsync(inicio, fim));
    }

    /// <summary>Produtos no estoque mínimo (procedure sp_produtos_estoque_baixo).</summary>
    [HttpGet("banco/estoque-baixo")]
    public async Task<ActionResult> GetEstoqueBaixo()
    {
        return this.ParaResposta(await _banco.ProdutosEstoqueBaixoAsync());
    }

    /// <summary>Histórico de estoque gravado pela trigger de auditoria.</summary>
    [HttpGet("banco/movimentacoes-estoque")]
    public async Task<ActionResult> GetMovimentacoesEstoque([FromQuery] int produtoId = 0, [FromQuery] int limite = 50)
    {
        return this.ParaResposta(await _banco.MovimentacoesEstoqueAsync(produtoId, limite));
    }

    /// <summary>Contas em aberto já vencidas (procedure sp_contas_vencidas).</summary>
    [HttpGet("banco/contas-vencidas")]
    public async Task<ActionResult> GetContasVencidas()
    {
        return this.ParaResposta(await _banco.ContasVencidasAsync());
    }
}
