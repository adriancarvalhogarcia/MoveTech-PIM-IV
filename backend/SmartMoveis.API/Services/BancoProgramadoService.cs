using System.Data;
using System.Data.Common;
using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;

namespace SmartMoveis.API.Services;

/// <summary>
/// Consultas que executam as stored procedures criadas na migration
/// ProceduresETriggers. Mostra a integração API ↔ banco programado:
/// a regra fica no MySQL e a API apenas chama a procedure.
/// </summary>
public interface IBancoProgramadoService
{
    Task<ResultadoServico<object>> ResumoVendasPeriodoAsync(DateTime? inicio, DateTime? fim);
    Task<ResultadoServico<object>> ProdutosEstoqueBaixoAsync();
    Task<ResultadoServico<object>> MovimentacoesEstoqueAsync(int produtoId, int limite);
    Task<ResultadoServico<object>> ContasVencidasAsync();
}

public class BancoProgramadoService : IBancoProgramadoService
{
    private readonly ApplicationDbContext _contexto;

    public BancoProgramadoService(ApplicationDbContext contexto)
    {
        _contexto = contexto;
    }

    public async Task<ResultadoServico<object>> ResumoVendasPeriodoAsync(DateTime? inicio, DateTime? fim)
    {
        var dataFim = (fim ?? DateTime.Today).Date;
        var dataInicio = (inicio ?? dataFim.AddDays(-30)).Date;

        if (dataInicio > dataFim)
        {
            return ResultadoServico<object>.Invalido("A data inicial deve ser menor ou igual à data final.");
        }

        var linhas = await ExecutarAsync("sp_resumo_vendas_periodo",
            ("p_inicio", dataInicio),
            ("p_fim", dataFim));

        return ResultadoServico<object>.Ok(new
        {
            inicio = dataInicio.ToString("yyyy-MM-dd"),
            fim = dataFim.ToString("yyyy-MM-dd"),
            procedure = "sp_resumo_vendas_periodo",
            resumo = linhas.FirstOrDefault()
        });
    }

    public async Task<ResultadoServico<object>> ProdutosEstoqueBaixoAsync()
    {
        var linhas = await ExecutarAsync("sp_produtos_estoque_baixo");
        return ResultadoServico<object>.Ok(new { procedure = "sp_produtos_estoque_baixo", itens = linhas });
    }

    public async Task<ResultadoServico<object>> MovimentacoesEstoqueAsync(int produtoId, int limite)
    {
        if (produtoId < 0)
        {
            return ResultadoServico<object>.Invalido("Produto inválido.");
        }

        limite = Math.Clamp(limite, 1, 200);

        var linhas = await ExecutarAsync("sp_movimentacoes_estoque",
            ("p_produto_id", produtoId),
            ("p_limite", limite));

        return ResultadoServico<object>.Ok(new
        {
            procedure = "sp_movimentacoes_estoque",
            origem = "Registros gravados pela trigger trg_produtos_auditoria_estoque",
            itens = linhas
        });
    }

    public async Task<ResultadoServico<object>> ContasVencidasAsync()
    {
        var linhas = await ExecutarAsync("sp_contas_vencidas");
        return ResultadoServico<object>.Ok(new { procedure = "sp_contas_vencidas", itens = linhas });
    }

    /// <summary>
    /// Executa uma procedure (nome fixo, nunca vindo do usuário) com
    /// parâmetros tipados e devolve as linhas como dicionários.
    /// </summary>
    private async Task<List<Dictionary<string, object?>>> ExecutarAsync(
        string procedure, params (string Nome, object Valor)[] parametros)
    {
        var conexao = _contexto.Database.GetDbConnection();
        var abriuAqui = conexao.State != ConnectionState.Open;

        if (abriuAqui)
        {
            await conexao.OpenAsync();
        }

        try
        {
            await using DbCommand comando = conexao.CreateCommand();
            comando.CommandText = procedure;
            comando.CommandType = CommandType.StoredProcedure;

            foreach (var (nome, valor) in parametros)
            {
                var parametro = comando.CreateParameter();
                parametro.ParameterName = nome;
                parametro.Value = valor;
                comando.Parameters.Add(parametro);
            }

            var linhas = new List<Dictionary<string, object?>>();

            await using var leitor = await comando.ExecuteReaderAsync();
            while (await leitor.ReadAsync())
            {
                var linha = new Dictionary<string, object?>();
                for (var i = 0; i < leitor.FieldCount; i++)
                {
                    var nome = leitor.GetName(i);
                    var chave = char.ToLowerInvariant(nome[0]) + nome[1..];
                    linha[chave] = leitor.IsDBNull(i) ? null : leitor.GetValue(i);
                }
                linhas.Add(linha);
            }

            return linhas;
        }
        finally
        {
            if (abriuAqui)
            {
                await conexao.CloseAsync();
            }
        }
    }
}
