using Microsoft.EntityFrameworkCore;
using SmartMoveis.API.Data;

namespace SmartMoveis.API.Services;

public interface IRelatorioService
{
    Task<object> ObterDashboardAsync();
    Task<ResultadoServico<object>> ObterAnaliseInteligenteAsync();
}

/// <summary>
/// Indicadores do dashboard e análise inteligente (regressão linear
/// sobre o faturamento mensal). Concentra as consultas e os cálculos
/// que antes ficavam no controller.
/// </summary>
public class RelatorioService : IRelatorioService
{
    private readonly ApplicationDbContext _context;

    public RelatorioService(ApplicationDbContext context)
    {
        _context = context;
    }

    // =========================================================
    // DASHBOARD / RELATÓRIOS
    // =========================================================

    public async Task<object> ObterDashboardAsync()
    {
        var totalClientesAtivos = await _context.Clientes
            .CountAsync(c => c.Ativo);

        var totalProdutosAtivos = await _context.Produtos
            .CountAsync(p => p.Ativo);

        var totalProdutosEstoqueBaixo = await _context.Produtos
            .CountAsync(p =>
                p.Ativo &&
                p.QuantidadeEstoque <= p.EstoqueMinimo
            );

        var totalVendas = await _context.Vendas.CountAsync();

        // Faturamento líquido: desconta o que foi devolvido.
        var faturamentoTotal = await _context.Vendas
            .SumAsync(v => (decimal?)(v.ValorTotal - v.ValorDevolvido)) ?? 0;

        var ticketMedio = totalVendas > 0
            ? faturamentoTotal / totalVendas
            : 0;

        var produtosEstoqueBaixo = await _context.Produtos
            .Where(p =>
                p.Ativo &&
                p.QuantidadeEstoque <= p.EstoqueMinimo
            )
            .OrderBy(p => p.QuantidadeEstoque)
            .Select(p => new
            {
                p.Id,
                p.Nome,
                p.QuantidadeEstoque,
                p.EstoqueMinimo
            })
            .ToListAsync();

        var produtosMaisVendidos = await _context.ItensVenda
            .GroupBy(i => new
            {
                i.ProdutoId,
                i.Produto!.Nome
            })
            .Select(g => new
            {
                ProdutoId = g.Key.ProdutoId,
                Produto = g.Key.Nome,
                QuantidadeVendida = g.Sum(i => i.Quantidade - i.QuantidadeDevolvida),
                Faturamento = g.Sum(i => i.PrecoUnitario * (i.Quantidade - i.QuantidadeDevolvida))
            })
            .OrderByDescending(p => p.QuantidadeVendida)
            .Take(5)
            .ToListAsync();

        var vendasRecentes = await _context.Vendas
            .OrderByDescending(v => v.CriadoEm)
            .Take(5)
            .Select(v => new
            {
                v.Id,

                Cliente = new
                {
                    v.Cliente!.Id,
                    v.Cliente.Nome
                },

                v.ValorTotal,
                v.CriadoEm
            })
            .ToListAsync();

        return new
        {
            resumo = new
            {
                totalClientesAtivos,
                totalProdutosAtivos,
                totalProdutosEstoqueBaixo,
                totalVendas,
                faturamentoTotal,
                ticketMedio
            },

            produtosEstoqueBaixo,
            produtosMaisVendidos,
            vendasRecentes
        };
    }

    // =========================================================
    // ANÁLISE INTELIGENTE
    // =========================================================

    public async Task<ResultadoServico<object>> ObterAnaliseInteligenteAsync()
    {
        /*
         * Busca o histórico real de vendas existente no banco.
         */

        var vendas = await _context.Vendas
            .AsNoTracking()
            .Select(v => new
            {
                v.CriadoEm,
                ValorTotal = v.ValorTotal - v.ValorDevolvido
            })
            .ToListAsync();

        var historicoReal = vendas
            .GroupBy(v => new
            {
                v.CriadoEm.Year,
                v.CriadoEm.Month
            })
            .Select(g => new HistoricoMensal
            {
                Ano = g.Key.Year,
                Mes = g.Key.Month,
                Faturamento = g.Sum(v => v.ValorTotal)
            })
            .OrderBy(h => h.Ano)
            .ThenBy(h => h.Mes)
            .ToList();

        /*
         * Para uma análise temporal minimamente representativa,
         * utilizamos a base real quando existem pelo menos
         * 12 períodos mensais.
         *
         * Enquanto o sistema não possui esse histórico,
         * é utilizada uma base simulada exclusivamente
         * para demonstração acadêmica.
         */

        const int minimoPeriodosReais = 12;

        List<HistoricoMensal> historicoUtilizado;
        string tipoBase;
        string descricaoBase;

        if (historicoReal.Count >= minimoPeriodosReais)
        {
            historicoUtilizado = historicoReal;

            tipoBase = "real";

            descricaoBase =
                "Análise realizada com o histórico real de vendas da MoveTech.";
        }
        else
        {
            historicoUtilizado = CriarBaseAcademicaSimulada();

            tipoBase = "simulada-academica";

            descricaoBase =
                "Base simulada para demonstração acadêmica. " +
                "O banco ainda não possui pelo menos 12 períodos mensais " +
                "com vendas reais para realizar a análise.";
        }

        // =====================================================
        // PREPARAÇÃO DA SÉRIE TEMPORAL
        // =====================================================

        var dados = historicoUtilizado
            .Select((item, indice) => new PontoRegressao
            {
                Periodo = indice + 1,
                Faturamento = (double)item.Faturamento
            })
            .ToList();

        /*
         * Os últimos quatro períodos ficam reservados para
         * avaliar a capacidade de previsão.
         *
         * Como se trata de dados temporais, a divisão é
         * cronológica e não aleatória.
         */

        const int quantidadeTesteDesejada = 4;

        var quantidadeTeste = Math.Min(
            quantidadeTesteDesejada,
            Math.Max(1, dados.Count / 4)
        );

        var quantidadeTreinamento =
            dados.Count - quantidadeTeste;

        if (quantidadeTreinamento < 2)
        {
            return ResultadoServico<object>.Invalido(
                "Não existem períodos suficientes para realizar a análise.");
        }

        var dadosTreino = dados
            .Take(quantidadeTreinamento)
            .ToList();

        var dadosTeste = dados
            .Skip(quantidadeTreinamento)
            .ToList();

        // =====================================================
        // MODELO DE REGRESSÃO — AVALIAÇÃO
        // =====================================================

        /*
         * É aplicada regressão linear simples pelo método
         * dos mínimos quadrados.
         *
         * X = período temporal
         * Y = faturamento
         *
         * Equação:
         *
         * Y = intercepto + coeficiente * X
         */

        var modeloAvaliacao =
            CalcularRegressaoLinear(dadosTreino);

        var resultadosTeste = dadosTeste
            .Select(item => new ResultadoTeste
            {
                Real = item.Faturamento,

                Previsto = Prever(
                    modeloAvaliacao,
                    item.Periodo
                )
            })
            .ToList();

        // =====================================================
        // MÉTRICAS
        // =====================================================

        var mae =
            resultadosTeste
                .Average(resultado =>
                    Math.Abs(
                        resultado.Real -
                        resultado.Previsto
                    )
                );

        var rmse =
            Math.Sqrt(
                resultadosTeste
                    .Average(resultado =>
                        Math.Pow(
                            resultado.Real -
                            resultado.Previsto,
                            2
                        )
                    )
            );

        /*
         * R² calculado sobre o conjunto de teste.
         *
         * Um R² negativo pode ocorrer quando o modelo
         * generaliza pior do que simplesmente utilizar
         * a média dos valores observados.
         *
         * O valor é mantido sem manipulação porque faz
         * parte da avaliação acadêmica do modelo.
         */

        var mediaTeste =
            resultadosTeste
                .Average(resultado =>
                    resultado.Real
                );

        var somaQuadradosResiduos =
            resultadosTeste
                .Sum(resultado =>
                    Math.Pow(
                        resultado.Real -
                        resultado.Previsto,
                        2
                    )
                );

        var somaQuadradosTotais =
            resultadosTeste
                .Sum(resultado =>
                    Math.Pow(
                        resultado.Real -
                        mediaTeste,
                        2
                    )
                );

        double r2;

        if (somaQuadradosTotais > 0)
        {
            r2 =
                1 -
                (
                    somaQuadradosResiduos /
                    somaQuadradosTotais
                );
        }
        else
        {
            r2 = 0;
        }

        // =====================================================
        // MODELO FINAL
        // =====================================================

        /*
         * A avaliação acima continua utilizando somente
         * os dados de treinamento.
         *
         * Após calcular as métricas, criamos o modelo final
         * utilizando todo o histórico disponível.
         *
         * Dessa forma:
         *
         * - as métricas continuam honestas;
         * - a previsão futura aproveita os 24 períodos.
         */

        var modeloFinal =
            CalcularRegressaoLinear(dados);

        // =====================================================
        // PRÓXIMO MÊS
        // =====================================================

        var ultimoRegistro =
            historicoUtilizado.Last();

        var dataUltimoRegistro =
            new DateTime(
                ultimoRegistro.Ano,
                ultimoRegistro.Mes,
                1
            );

        var proximoMes =
            dataUltimoRegistro.AddMonths(1);

        var proximoPeriodo =
            dados.Count + 1;

        var faturamentoPrevisto =
            Prever(
                modeloFinal,
                proximoPeriodo
            );

        /*
         * Não faz sentido apresentar faturamento negativo.
         */

        faturamentoPrevisto =
            Math.Max(
                0,
                faturamentoPrevisto
            );

        // =====================================================
        // ANÁLISE DESCRITIVA
        // =====================================================

        var faturamentos =
            historicoUtilizado
                .Select(h => h.Faturamento)
                .ToList();

        var mediaMensal =
            faturamentos.Average();

        var maiorFaturamento =
            faturamentos.Max();

        var menorFaturamento =
            faturamentos.Min();

        var primeiroFaturamento =
            faturamentos.First();

        var ultimoFaturamento =
            faturamentos.Last();

        decimal crescimentoPercentual = 0;

        if (primeiroFaturamento > 0)
        {
            crescimentoPercentual =
                (
                    (ultimoFaturamento - primeiroFaturamento)
                    / primeiroFaturamento
                ) * 100;
        }

        var tendencia =
            crescimentoPercentual > 3
                ? "Crescimento"
                : crescimentoPercentual < -3
                    ? "Queda"
                    : "Estabilidade";

        // =====================================================
        // HISTÓRICO PARA O GRÁFICO
        // =====================================================

        var historicoResposta =
            historicoUtilizado
                .Select((h, indice) => new
                {
                    periodo =
                        indice + 1,

                    ano =
                        h.Ano,

                    mes =
                        h.Mes,

                    mesNome =
                        ObterNomeMes(h.Mes),

                    referencia =
                        $"{ObterNomeMes(h.Mes)}/{h.Ano}",

                    faturamento =
                        Math.Round(
                            h.Faturamento,
                            2
                        )
                })
                .ToList();

        // =====================================================
        // INTERPRETAÇÃO
        // =====================================================

        string interpretacaoTendencia;

        if (tendencia == "Crescimento")
        {
            interpretacaoTendencia =
                "O histórico apresenta tendência geral de crescimento " +
                "do faturamento ao longo do período analisado.";
        }
        else if (tendencia == "Queda")
        {
            interpretacaoTendencia =
                "O histórico apresenta tendência geral de redução " +
                "do faturamento ao longo do período analisado.";
        }
        else
        {
            interpretacaoTendencia =
                "O histórico apresenta comportamento relativamente " +
                "estável ao longo do período analisado.";
        }

        string interpretacaoModelo;

        if (r2 >= 0.75)
        {
            interpretacaoModelo =
                "No conjunto de teste, a regressão apresentou forte " +
                "capacidade de representar a tendência observada.";
        }
        else if (r2 >= 0.50)
        {
            interpretacaoModelo =
                "No conjunto de teste, a regressão apresentou capacidade " +
                "moderada de representar a tendência observada.";
        }
        else if (r2 >= 0)
        {
            interpretacaoModelo =
                "No conjunto de teste, a regressão apresentou capacidade " +
                "limitada de representar as oscilações observadas.";
        }
        else
        {
            interpretacaoModelo =
                "O R² do conjunto de teste ficou negativo, indicando que " +
                "uma tendência linear simples não representa adequadamente " +
                "todas as oscilações dos últimos períodos. A previsão deve " +
                "ser interpretada apenas como uma estimativa acadêmica de tendência.";
        }

        var interpretacao =
            interpretacaoTendencia +
            " " +
            interpretacaoModelo;

        // =====================================================
        // RESPOSTA
        // =====================================================

        return ResultadoServico<object>.Ok(new
        {
            tipoBase,

            descricaoBase,

            modelo = new
            {
                nome =
                    "Regressão Linear",

                tecnologia =
                    "Análise estatística em C#",

                metodo =
                    "Mínimos quadrados ordinários",

                objetivo =
                    "Estimar a tendência do faturamento e o valor do próximo período mensal.",

                variavelAlvo =
                    "Faturamento",

                variaveisEntrada = new[]
                {
                    "Período temporal"
                },

                quantidadePeriodos =
                    historicoUtilizado.Count,

                quantidadeTreinamento =
                    dadosTreino.Count,

                quantidadeTeste =
                    dadosTeste.Count,

                coeficiente =
                    Math.Round(
                        modeloFinal.Coeficiente,
                        4
                    ),

                intercepto =
                    Math.Round(
                        modeloFinal.Intercepto,
                        2
                    )
            },

            resumo = new
            {
                mediaMensal =
                    Math.Round(
                        mediaMensal,
                        2
                    ),

                maiorFaturamento =
                    Math.Round(
                        maiorFaturamento,
                        2
                    ),

                menorFaturamento =
                    Math.Round(
                        menorFaturamento,
                        2
                    ),

                crescimentoPercentual =
                    Math.Round(
                        crescimentoPercentual,
                        2
                    ),

                tendencia
            },

            metricas = new
            {
                mae =
                    Math.Round(
                        mae,
                        2
                    ),

                rmse =
                    Math.Round(
                        rmse,
                        2
                    ),

                r2 =
                    Math.Round(
                        r2,
                        4
                    )
            },

            previsao = new
            {
                ano =
                    proximoMes.Year,

                mes =
                    proximoMes.Month,

                mesNome =
                    ObterNomeMes(
                        proximoMes.Month
                    ),

                referencia =
                    $"{ObterNomeMes(proximoMes.Month)}/{proximoMes.Year}",

                faturamentoPrevisto =
                    Math.Round(
                        faturamentoPrevisto,
                        2
                    )
            },

            interpretacao,

            historico =
                historicoResposta,

            observacao =
                tipoBase == "simulada-academica"

                    ? "Os resultados desta análise têm finalidade acadêmica " +
                      "e utilizam dados simulados. A previsão representa uma " +
                      "estimativa de tendência e não uma projeção financeira " +
                      "real da empresa."

                    : "A análise utiliza o histórico real disponível no sistema. " +
                      "A previsão representa uma estimativa baseada na tendência " +
                      "histórica e não constitui garantia de faturamento futuro."
        });
    }

    // =========================================================
    // REGRESSÃO LINEAR POR MÍNIMOS QUADRADOS
    // =========================================================

    private static ModeloRegressao
        CalcularRegressaoLinear(
            IReadOnlyCollection<PontoRegressao> dados
        )
    {
        if (dados.Count < 2)
        {
            throw new InvalidOperationException(
                "São necessários pelo menos dois pontos para calcular a regressão."
            );
        }

        var mediaX =
            dados.Average(
                item => item.Periodo
            );

        var mediaY =
            dados.Average(
                item => item.Faturamento
            );

        var numerador =
            dados.Sum(item =>
                (
                    item.Periodo -
                    mediaX
                )
                *
                (
                    item.Faturamento -
                    mediaY
                )
            );

        var denominador =
            dados.Sum(item =>
                Math.Pow(
                    item.Periodo -
                    mediaX,
                    2
                )
            );

        var coeficiente =
            denominador == 0
                ? 0
                : numerador / denominador;

        var intercepto =
            mediaY -
            (
                coeficiente *
                mediaX
            );

        return new ModeloRegressao
        {
            Coeficiente =
                coeficiente,

            Intercepto =
                intercepto
        };
    }

    // =========================================================
    // PREVISÃO
    // =========================================================

    private static double Prever(
        ModeloRegressao modelo,
        double periodo
    )
    {
        return modelo.Intercepto +
               (
                   modelo.Coeficiente *
                   periodo
               );
    }

    // =========================================================
    // BASE SIMULADA PARA FINS ACADÊMICOS
    // =========================================================

    private static List<HistoricoMensal>
        CriarBaseAcademicaSimulada()
    {
        /*
         * Base fictícia contendo 24 meses.
         *
         * Os dados simulam o faturamento mensal de uma
         * empresa do segmento de móveis.
         *
         * Há tendência de crescimento, mas também existem
         * oscilações mensais para evitar uma série
         * artificialmente perfeita.
         */

        decimal[] faturamentos =
        {
            11200.00m,
            11850.00m,
            12100.00m,
            11950.00m,
            12800.00m,
            13450.00m,
            13900.00m,
            14350.00m,
            15100.00m,
            15800.00m,
            16650.00m,
            17800.00m,

            14900.00m,
            15450.00m,
            16100.00m,
            16850.00m,
            17600.00m,
            18450.00m,
            19100.00m,
            19850.00m,
            20700.00m,
            21650.00m,
            22900.00m,
            24150.00m
        };

        var inicio =
            new DateTime(
                2024,
                10,
                1
            );

        var historico =
            new List<HistoricoMensal>();

        for (
            var indice = 0;
            indice < faturamentos.Length;
            indice++
        )
        {
            var data =
                inicio.AddMonths(indice);

            historico.Add(
                new HistoricoMensal
                {
                    Ano =
                        data.Year,

                    Mes =
                        data.Month,

                    Faturamento =
                        faturamentos[indice]
                }
            );
        }

        return historico;
    }

    // =========================================================
    // NOME DO MÊS
    // =========================================================

    private static string ObterNomeMes(int mes)
    {
        return mes switch
        {
            1 => "Jan",
            2 => "Fev",
            3 => "Mar",
            4 => "Abr",
            5 => "Mai",
            6 => "Jun",
            7 => "Jul",
            8 => "Ago",
            9 => "Set",
            10 => "Out",
            11 => "Nov",
            12 => "Dez",
            _ => "-"
        };
    }

    // =========================================================
    // CLASSES INTERNAS
    // =========================================================

    private sealed class HistoricoMensal
    {
        public int Ano { get; set; }

        public int Mes { get; set; }

        public decimal Faturamento { get; set; }
    }

    private sealed class PontoRegressao
    {
        public double Periodo { get; set; }

        public double Faturamento { get; set; }
    }

    private sealed class ModeloRegressao
    {
        public double Coeficiente { get; set; }

        public double Intercepto { get; set; }
    }

    private sealed class ResultadoTeste
    {
        public double Real { get; set; }

        public double Previsto { get; set; }
    }
}