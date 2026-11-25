const API_URL = "http://localhost:5071/api";

const token = sessionStorage.getItem("smartmoveis_token");
const usuarioSalvo = sessionStorage.getItem("smartmoveis_usuario");

let dadosDashboard = null;
let graficoProdutos = null;
let dadosAnaliseInteligente = null;
let graficoPrevisao = null;


/* =========================================================
   ELEMENTOS
   ========================================================= */

const usuarioNome =
    document.getElementById("usuario-nome");

const usuarioPerfil =
    document.getElementById("usuario-perfil");

const botaoSair =
    document.getElementById("botao-sair");

const botaoExportar =
    document.getElementById("botao-exportar");

const faturamentoTotal =
    document.getElementById("faturamento-total");

const totalVendas =
    document.getElementById("total-vendas");

const ticketMedio =
    document.getElementById("ticket-medio");

const clientesAtivos =
    document.getElementById("clientes-ativos");

const produtosAtivos =
    document.getElementById("produtos-ativos");

const estoqueBaixo =
    document.getElementById("estoque-baixo");

const listaEstoque =
    document.getElementById("lista-estoque");

const tabelaVendasRecentes =
    document.getElementById("tabela-vendas-recentes");

const mensagemRelatorios =
    document.getElementById("mensagem-relatorios");


/* =========================================================
   ELEMENTOS — MACHINE LEARNING
   ========================================================= */

const mlBaseBadge =
    document.getElementById("ml-base-badge");

const mlPrevisaoValor =
    document.getElementById("ml-previsao-valor");

const mlPrevisaoReferencia =
    document.getElementById("ml-previsao-referencia");

const mlTendencia =
    document.getElementById("ml-tendencia");

const mlCrescimento =
    document.getElementById("ml-crescimento");

const mlMediaMensal =
    document.getElementById("ml-media-mensal");

const mlModelo =
    document.getElementById("ml-modelo");

const mlPeriodos =
    document.getElementById("ml-periodos");

const mlMae =
    document.getElementById("ml-mae");

const mlRmse =
    document.getElementById("ml-rmse");

const mlR2 =
    document.getElementById("ml-r2");

const mlTreinamento =
    document.getElementById("ml-treinamento");

const mlTeste =
    document.getElementById("ml-teste");

const mlInterpretacao =
    document.getElementById("ml-interpretacao");

const mlObservacao =
    document.getElementById("ml-observacao");


/* =========================================================
   AUTENTICAÇÃO
   ========================================================= */

if (!token) {
    window.location.href = "index.html";
}


/* =========================================================
   USUÁRIO
   ========================================================= */

function carregarUsuario() {

    if (!usuarioSalvo) {
        return;
    }

    try {

        const usuario =
            JSON.parse(usuarioSalvo);

        usuarioNome.textContent =
            usuario.nome ||
            usuario.Nome ||
            "Administrador MoveTech";

        usuarioPerfil.textContent =
            usuario.perfil ||
            usuario.Perfil ||
            "Administrador";

    } catch {

        usuarioNome.textContent =
            "Administrador MoveTech";

        usuarioPerfil.textContent =
            "Administrador";
    }
}


/* =========================================================
   FORMATADORES
   ========================================================= */

function formatarMoeda(valor) {

    return Number(valor || 0)
        .toLocaleString(
            "pt-BR",
            {
                style: "currency",
                currency: "BRL"
            }
        );
}


function formatarData(data) {

    if (!data) {
        return "-";
    }

    const dataConvertida =
        new Date(data);

    return dataConvertida
        .toLocaleString("pt-BR");
}


/* =========================================================
   MENSAGENS
   ========================================================= */

function mostrarMensagem(texto, erro = false) {

    mensagemRelatorios.textContent =
        texto;

    mensagemRelatorios.classList
        .toggle("erro", erro);

    mensagemRelatorios.hidden = false;


    setTimeout(() => {

        mensagemRelatorios.hidden = true;

    }, 4500);
}


/* =========================================================
   API
   ========================================================= */

async function requisicaoApi(endpoint) {

    const resposta =
        await fetch(
            `${API_URL}${endpoint}`,
            {
                headers: {
                    Authorization:
                        `Bearer ${token}`
                }
            }
        );


    if (resposta.status === 401) {

        sessionStorage.removeItem(
            "smartmoveis_token"
        );

        sessionStorage.removeItem(
            "smartmoveis_usuario"
        );

        window.location.href =
            "index.html";

        throw new Error(
            "Sessão expirada."
        );
    }


    if (!resposta.ok) {

        let mensagemErro =
            `Erro ${resposta.status}`;

        try {

            const dadosErro =
                await resposta.json();

            mensagemErro =
                dadosErro.mensagem ||
                dadosErro.title ||
                mensagemErro;

        } catch {
            // Mantém a mensagem padrão.
        }

        throw new Error(
            mensagemErro
        );
    }


    return resposta.json();
}


/* =========================================================
   CARREGAR RELATÓRIO
   ========================================================= */

async function carregarRelatorios() {

    try {

        dadosDashboard =
            await requisicaoApi(
                "/relatorios/dashboard"
            );


        preencherResumo(
            dadosDashboard.resumo
        );


        preencherEstoque(
            dadosDashboard.produtosEstoqueBaixo
        );


        preencherVendasRecentes(
            dadosDashboard.vendasRecentes
        );


        criarGraficoProdutos(
            dadosDashboard.produtosMaisVendidos
        );

    } catch (erro) {

        console.error(erro);

        mostrarMensagem(
            "Não foi possível carregar os relatórios.",
            true
        );
    }
}


/* =========================================================
   RESUMO
   ========================================================= */

function preencherResumo(resumo) {

    faturamentoTotal.textContent =
        formatarMoeda(
            resumo.faturamentoTotal
        );

    totalVendas.textContent =
        resumo.totalVendas ?? 0;

    ticketMedio.textContent =
        formatarMoeda(
            resumo.ticketMedio
        );

    clientesAtivos.textContent =
        resumo.totalClientesAtivos ?? 0;

    produtosAtivos.textContent =
        resumo.totalProdutosAtivos ?? 0;

    estoqueBaixo.textContent =
        resumo.totalProdutosEstoqueBaixo ?? 0;
}


/* =========================================================
   ESTOQUE
   ========================================================= */

function preencherEstoque(produtos) {

    listaEstoque.innerHTML = "";


    if (!produtos || produtos.length === 0) {

        listaEstoque.innerHTML = `
            <p class="loading-text">
                Nenhum produto com estoque baixo.
            </p>
        `;

        return;
    }


    produtos.forEach(produto => {

        const item =
            document.createElement("div");

        item.className =
            "stock-item";


        const nome =
            document.createElement("div");

        nome.className =
            "stock-name";


        const titulo =
            document.createElement("strong");

        titulo.textContent =
            produto.nome;


        const detalhe =
            document.createElement("small");

        detalhe.textContent =
            `Estoque mínimo: ${produto.estoqueMinimo}`;


        nome.appendChild(titulo);
        nome.appendChild(detalhe);


        const quantidade =
            document.createElement("div");

        quantidade.className =
            "stock-value";

        quantidade.textContent =
            `${produto.quantidadeEstoque} un.`;


        item.appendChild(nome);
        item.appendChild(quantidade);

        listaEstoque.appendChild(item);
    });
}


/* =========================================================
   VENDAS RECENTES
   ========================================================= */

function preencherVendasRecentes(vendas) {

    tabelaVendasRecentes.innerHTML =
        "";


    if (!vendas || vendas.length === 0) {

        tabelaVendasRecentes.innerHTML = `
            <tr>
                <td
                    colspan="4"
                    class="empty-state"
                >
                    Nenhuma venda registrada.
                </td>
            </tr>
        `;

        return;
    }


    vendas.forEach(venda => {

        const linha =
            document.createElement("tr");


        const colunaId =
            document.createElement("td");

        colunaId.textContent =
            `#${venda.id}`;


        const colunaCliente =
            document.createElement("td");

        colunaCliente.textContent =
            venda.cliente?.nome ||
            "Cliente não informado";


        const colunaData =
            document.createElement("td");

        colunaData.textContent =
            formatarData(
                venda.criadoEm
            );


        const colunaValor =
            document.createElement("td");

        colunaValor.className =
            "valor-venda";

        colunaValor.textContent =
            formatarMoeda(
                venda.valorTotal
            );


        linha.appendChild(colunaId);
        linha.appendChild(colunaCliente);
        linha.appendChild(colunaData);
        linha.appendChild(colunaValor);


        tabelaVendasRecentes.appendChild(
            linha
        );
    });
}


/* =========================================================
   GRÁFICO — PRODUTOS MAIS VENDIDOS
   ========================================================= */

function criarGraficoProdutos(produtos) {

    const canvas =
        document.getElementById(
            "grafico-produtos"
        );


    if (!canvas) {
        return;
    }


    if (
        typeof Chart ===
        "undefined"
    ) {

        console.error(
            "Chart.js não foi carregado."
        );

        return;
    }


    if (graficoProdutos) {
        graficoProdutos.destroy();
    }


    const nomes =
        produtos?.map(
            produto =>
                produto.produto
        ) || [];


    const quantidades =
        produtos?.map(
            produto =>
                produto.quantidadeVendida
        ) || [];


    graficoProdutos =
        new Chart(
            canvas,
            {
                type: "bar",

                data: {

                    labels: nomes,

                    datasets: [
                        {
                            label:
                                "Quantidade vendida",

                            data:
                                quantidades,

                            backgroundColor:
                                "rgba(50, 224, 95, 0.65)",

                            borderColor:
                                "#32e05f",

                            borderWidth:
                                1,

                            borderRadius:
                                7
                        }
                    ]
                },

                options: {

                    responsive:
                        true,

                    maintainAspectRatio:
                        false,

                    plugins: {

                        legend: {
                            display:
                                false
                        }
                    },

                    scales: {

                        x: {

                            ticks: {
                                color:
                                    "#9da8a0"
                            },

                            grid: {
                                display:
                                    false
                            }
                        },

                        y: {

                            beginAtZero:
                                true,

                            ticks: {

                                color:
                                    "#9da8a0",

                                precision:
                                    0
                            },

                            grid: {

                                color:
                                    "rgba(140, 165, 145, 0.10)"
                            }
                        }
                    }
                }
            }
        );
}


/* =========================================================
   ANÁLISE INTELIGENTE — MACHINE LEARNING
   ========================================================= */

async function carregarAnaliseInteligente() {

    try {

        dadosAnaliseInteligente =
            await requisicaoApi(
                "/relatorios/analise-inteligente"
            );


        preencherAnaliseInteligente(
            dadosAnaliseInteligente
        );


        criarGraficoPrevisao(
            dadosAnaliseInteligente
        );

    } catch (erro) {

        console.error(
            "Erro ao carregar análise inteligente:",
            erro
        );


        if (mlBaseBadge) {

            mlBaseBadge.textContent =
                "Análise indisponível";

            mlBaseBadge.classList
                .remove("simulada");

            mlBaseBadge.classList
                .add("erro");
        }


        if (mlInterpretacao) {

            mlInterpretacao.textContent =
                "Não foi possível carregar a análise preditiva neste momento.";
        }


        if (mlObservacao) {

            mlObservacao.textContent =
                "Verifique se a API do MoveTech está em execução.";
        }
    }
}


/* =========================================================
   PREENCHER ANÁLISE INTELIGENTE
   ========================================================= */

function preencherAnaliseInteligente(dados) {

    if (!dados) {
        return;
    }


    const baseSimulada =
        dados.tipoBase ===
        "simulada-academica";


    /* BASE UTILIZADA */

    if (mlBaseBadge) {

        mlBaseBadge.classList
            .remove("erro");

        mlBaseBadge.classList
            .toggle(
                "simulada",
                baseSimulada
            );


        mlBaseBadge.textContent =
            baseSimulada
                ? "Base simulada • acadêmica"
                : "Base real • MoveTech";
    }


    /* PREVISÃO */

    if (mlPrevisaoValor) {

        mlPrevisaoValor.textContent =
            formatarMoeda(
                dados.previsao
                    ?.faturamentoPrevisto
            );
    }


    if (mlPrevisaoReferencia) {

        mlPrevisaoReferencia.textContent =
            dados.previsao?.referencia
                ? `Previsão para ${dados.previsao.referencia}`
                : "Próximo período";
    }


    /* TENDÊNCIA */

    if (mlTendencia) {

        mlTendencia.textContent =
            dados.resumo?.tendencia ||
            "—";
    }


    if (mlCrescimento) {

        const crescimento =
            Number(
                dados.resumo
                    ?.crescimentoPercentual ||
                0
            );


        const sinal =
            crescimento > 0
                ? "+"
                : "";


        mlCrescimento.textContent =
            `${sinal}${crescimento.toLocaleString(
                "pt-BR",
                {
                    minimumFractionDigits:
                        2,

                    maximumFractionDigits:
                        2
                }
            )}% no período`;
    }


    /* MÉDIA */

    if (mlMediaMensal) {

        mlMediaMensal.textContent =
            formatarMoeda(
                dados.resumo
                    ?.mediaMensal
            );
    }


    /* MODELO */

    if (mlModelo) {

        mlModelo.textContent =
            dados.modelo?.nome ||
            "Regressão SDCA";
    }


    if (mlPeriodos) {

        const quantidade =
            dados.modelo
                ?.quantidadePeriodos ??
            0;


        mlPeriodos.textContent =
            `${quantidade} períodos analisados`;
    }


    /* MÉTRICAS */

    if (mlMae) {

        mlMae.textContent =
            formatarMoeda(
                dados.metricas?.mae
            );
    }


    if (mlRmse) {

        mlRmse.textContent =
            formatarMoeda(
                dados.metricas?.rmse
            );
    }


    if (mlR2) {

        const valorR2 =
            Number(
                dados.metricas?.r2 ??
                0
            );


        mlR2.textContent =
            valorR2.toLocaleString(
                "pt-BR",
                {
                    minimumFractionDigits:
                        4,

                    maximumFractionDigits:
                        4
                }
            );
    }


    /* TREINAMENTO / TESTE */

    if (mlTreinamento) {

        mlTreinamento.textContent =
            `${dados.modelo
                ?.quantidadeTreinamento ?? 0} períodos`;
    }


    if (mlTeste) {

        mlTeste.textContent =
            `${dados.modelo
                ?.quantidadeTeste ?? 0} períodos`;
    }


    /* INTERPRETAÇÃO */

    if (mlInterpretacao) {

        mlInterpretacao.textContent =
            dados.interpretacao ||
            "Análise concluída.";
    }


    if (mlObservacao) {

        mlObservacao.textContent =
            dados.observacao ||
            dados.descricaoBase ||
            "";
    }
}


/* =========================================================
   GRÁFICO — HISTÓRICO × PREVISÃO
   ========================================================= */

function criarGraficoPrevisao(dados) {

    const canvas =
        document.getElementById(
            "grafico-previsao"
        );


    if (!canvas) {
        return;
    }


    if (
        typeof Chart ===
        "undefined"
    ) {

        console.error(
            "Chart.js não foi carregado."
        );

        return;
    }


    if (graficoPrevisao) {

        graficoPrevisao
            .destroy();
    }


    const historico =
        dados?.historico ||
        [];


    const labels =
        historico.map(
            item =>
                item.referencia
        );


    const valoresHistoricos =
        historico.map(
            item =>
                Number(
                    item.faturamento ||
                    0
                )
        );


    const referenciaPrevisao =
        dados?.previsao
            ?.referencia ||
        "Previsão";


    const valorPrevisao =
        Number(
            dados?.previsao
                ?.faturamentoPrevisto ||
            0
        );


    labels.push(
        referenciaPrevisao
    );


    /*
     * Histórico:
     * mostra todos os meses reais/simulados.
     * No ponto futuro fica null.
     */

    const serieHistorica = [
        ...valoresHistoricos,
        null
    ];


    /*
     * Previsão:
     * fica vazia até o último mês histórico.
     * Depois liga o último faturamento ao valor previsto.
     */

    const seriePrevisao =
        new Array(
            Math.max(
                labels.length - 2,
                0
            )
        ).fill(null);


    if (
        valoresHistoricos.length >
        0
    ) {

        seriePrevisao.push(
            valoresHistoricos[
                valoresHistoricos.length -
                1
            ]
        );
    }


    seriePrevisao.push(
        valorPrevisao
    );


    graficoPrevisao =
        new Chart(
            canvas,
            {
                type:
                    "line",

                data: {

                    labels,

                    datasets: [

                        /* HISTÓRICO */

                        {
                            label:
                                "Histórico",

                            data:
                                serieHistorica,

                            borderColor:
                                "#32e05f",

                            backgroundColor:
                                "rgba(50, 224, 95, 0.08)",

                            pointBackgroundColor:
                                "#32e05f",

                            pointBorderColor:
                                "#08110a",

                            pointRadius:
                                3,

                            pointHoverRadius:
                                5,

                            borderWidth:
                                2,

                            tension:
                                0.28,

                            fill:
                                true,

                            spanGaps:
                                false
                        },


                        /* PREVISÃO */

                        {
                            label:
                                "Previsão",

                            data:
                                seriePrevisao,

                            borderColor:
                                "#ffd36b",

                            backgroundColor:
                                "#ffd36b",

                            pointBackgroundColor:
                                "#ffd36b",

                            pointBorderColor:
                                "#151108",

                            pointRadius:
                                5,

                            pointHoverRadius:
                                7,

                            borderWidth:
                                2,

                            borderDash:
                                [7, 6],

                            tension:
                                0.2,

                            fill:
                                false,

                            spanGaps:
                                true
                        }
                    ]
                },


                options: {

                    responsive:
                        true,

                    maintainAspectRatio:
                        false,


                    interaction: {

                        mode:
                            "index",

                        intersect:
                            false
                    },


                    plugins: {

                        legend: {

                            labels: {

                                color:
                                    "#aeb8b0",

                                usePointStyle:
                                    true,

                                boxWidth:
                                    8
                            }
                        },


                        tooltip: {

                            callbacks: {

                                label:
                                    contexto => {

                                        if (
                                            contexto.raw ===
                                            null
                                        ) {

                                            return "";
                                        }


                                        return (
                                            `${contexto.dataset.label}: ` +
                                            formatarMoeda(
                                                contexto.raw
                                            )
                                        );
                                    }
                            }
                        }
                    },


                    scales: {

                        x: {

                            ticks: {

                                color:
                                    "#8f9a92",

                                maxRotation:
                                    45,

                                minRotation:
                                    0
                            },

                            grid: {

                                display:
                                    false
                            }
                        },


                        y: {

                            beginAtZero:
                                false,

                            ticks: {

                                color:
                                    "#8f9a92",

                                callback:
                                    valor =>

                                        Number(valor)
                                            .toLocaleString(
                                                "pt-BR",
                                                {
                                                    style:
                                                        "currency",

                                                    currency:
                                                        "BRL",

                                                    maximumFractionDigits:
                                                        0
                                                }
                                            )
                            },

                            grid: {

                                color:
                                    "rgba(140, 165, 145, 0.10)"
                            }
                        }
                    }
                }
            }
        );
}


/* =========================================================
   EXPORTAÇÃO PARA EXCEL
   ========================================================= */

async function exportarExcel() {

    if (
        typeof XLSX ===
        "undefined"
    ) {

        mostrarMensagem(
            "O recurso de exportação para Excel não foi carregado.",
            true
        );

        return;
    }


    botaoExportar.disabled =
        true;


    const textoOriginal =
        botaoExportar.textContent;


    botaoExportar.textContent =
        "Gerando Excel...";


    try {

        /*
         * Buscamos os dados completos.
         * O dashboard sozinho traz apenas
         * resumos e os 5 registros recentes.
         */

        const resultados =
            await Promise.all([
                requisicaoApi(
                    "/vendas"
                ),

                requisicaoApi(
                    "/produtos"
                ),

                requisicaoApi(
                    "/clientes"
                )
            ]);


        const vendas =
            resultados[0] ||
            [];

        const produtos =
            resultados[1] ||
            [];

        const clientes =
            resultados[2] ||
            [];


        const workbook =
            XLSX.utils
                .book_new();


        /* =================================================
           RESUMO
           ================================================= */

        const resumo =
            dadosDashboard
                ?.resumo ||
            {};


        const dadosResumo = [

            [
                "MOVETECH — RELATÓRIO GERENCIAL"
            ],

            [],

            [
                "Indicador",
                "Valor"
            ],

            [
                "Faturamento total",
                resumo.faturamentoTotal ||
                0
            ],

            [
                "Vendas realizadas",
                resumo.totalVendas ||
                0
            ],

            [
                "Ticket médio",
                resumo.ticketMedio ||
                0
            ],

            [
                "Clientes ativos",
                resumo.totalClientesAtivos ||
                0
            ],

            [
                "Produtos ativos",
                resumo.totalProdutosAtivos ||
                0
            ],

            [
                "Produtos com estoque baixo",
                resumo.totalProdutosEstoqueBaixo ||
                0
            ],

            [],

            [
                "Gerado em",

                new Date()
                    .toLocaleString(
                        "pt-BR"
                    )
            ]
        ];


        const planilhaResumo =
            XLSX.utils
                .aoa_to_sheet(
                    dadosResumo
                );


        planilhaResumo["!cols"] = [
            {
                wch: 32
            },

            {
                wch: 24
            }
        ];


        XLSX.utils
            .book_append_sheet(
                workbook,
                planilhaResumo,
                "Resumo"
            );


        /* =================================================
           VENDAS
           ================================================= */

        const dadosVendas =
            vendas.map(
                venda => ({

                    Venda:
                        venda.id,

                    Cliente:
                        venda.cliente?.nome ||
                        venda.clienteNome ||
                        "-",

                    Data:
                        formatarData(
                            venda.criadoEm
                        ),

                    Itens:
                        venda.itens?.length ??
                        venda.quantidadeItens ??
                        "-",

                    Total:
                        Number(
                            venda.valorTotal ||
                            0
                        )
                })
            );


        const planilhaVendas =
            XLSX.utils
                .json_to_sheet(
                    dadosVendas
                );


        planilhaVendas["!cols"] = [

            {
                wch: 10
            },

            {
                wch: 35
            },

            {
                wch: 22
            },

            {
                wch: 12
            },

            {
                wch: 18
            }
        ];


        XLSX.utils
            .book_append_sheet(
                workbook,
                planilhaVendas,
                "Vendas"
            );


        /* =================================================
           PRODUTOS
           ================================================= */

        const dadosProdutos =
            produtos.map(
                produto => ({

                    Produto:
                        produto.nome,

                    Categoria:
                        produto.categoria ||
                        "-",

                    Preço:
                        Number(
                            produto.preco ||
                            0
                        ),

                    Estoque:
                        produto.quantidadeEstoque ??
                        0,

                    "Estoque mínimo":
                        produto.estoqueMinimo ??
                        0,

                    Status:
                        produto.ativo
                            ? "Ativo"
                            : "Inativo"
                })
            );


        const planilhaProdutos =
            XLSX.utils
                .json_to_sheet(
                    dadosProdutos
                );


        planilhaProdutos["!cols"] = [

            {
                wch: 38
            },

            {
                wch: 20
            },

            {
                wch: 16
            },

            {
                wch: 12
            },

            {
                wch: 16
            },

            {
                wch: 12
            }
        ];


        XLSX.utils
            .book_append_sheet(
                workbook,
                planilhaProdutos,
                "Produtos"
            );


        /* =================================================
           ESTOQUE
           ================================================= */

        const dadosEstoque =
            produtos.map(
                produto => {

                    const quantidade =
                        Number(
                            produto
                                .quantidadeEstoque ||
                            0
                        );


                    const minimo =
                        Number(
                            produto
                                .estoqueMinimo ||
                            0
                        );


                    return {

                        Produto:
                            produto.nome,

                        Categoria:
                            produto.categoria ||
                            "-",

                        "Estoque atual":
                            quantidade,

                        "Estoque mínimo":
                            minimo,

                        Situação:
                            !produto.ativo
                                ? "Produto inativo"

                                : quantidade <=
                                  minimo

                                    ? "Estoque baixo"

                                    : "Estoque normal"
                    };
                }
            );


        const planilhaEstoque =
            XLSX.utils
                .json_to_sheet(
                    dadosEstoque
                );


        planilhaEstoque["!cols"] = [

            {
                wch: 38
            },

            {
                wch: 20
            },

            {
                wch: 16
            },

            {
                wch: 16
            },

            {
                wch: 22
            }
        ];


        XLSX.utils
            .book_append_sheet(
                workbook,
                planilhaEstoque,
                "Estoque"
            );


        /* =================================================
           CLIENTES
           ================================================= */

        const dadosClientes =
            clientes.map(
                cliente => ({

                    Nome:
                        cliente.nome,

                    CPF:
                        cliente.cpf ||
                        "-",

                    Telefone:
                        cliente.telefone ||
                        "-",

                    Email:
                        cliente.email ||
                        "-",

                    Status:
                        cliente.ativo
                            ? "Ativo"
                            : "Inativo"
                })
            );


        const planilhaClientes =
            XLSX.utils
                .json_to_sheet(
                    dadosClientes
                );


        planilhaClientes["!cols"] = [

            {
                wch: 40
            },

            {
                wch: 18
            },

            {
                wch: 20
            },

            {
                wch: 38
            },

            {
                wch: 12
            }
        ];


        XLSX.utils
            .book_append_sheet(
                workbook,
                planilhaClientes,
                "Clientes"
            );


        /* =================================================
           MACHINE LEARNING
           ================================================= */

        if (dadosAnaliseInteligente) {

            const analise =
                dadosAnaliseInteligente;


            const dadosMachineLearning = [

                [
                    "MOVETECH — ANÁLISE INTELIGENTE"
                ],

                [],

                [
                    "Informação",
                    "Valor"
                ],

                [
                    "Tipo da base",
                    analise.tipoBase ||
                    "-"
                ],

                [
                    "Modelo",
                    analise.modelo?.nome ||
                    "-"
                ],

                [
                    "Tecnologia",
                    analise.modelo?.tecnologia ||
                    "ML.NET"
                ],

                [
                    "Períodos analisados",
                    analise.modelo
                        ?.quantidadePeriodos ??
                    0
                ],

                [
                    "Períodos de treinamento",
                    analise.modelo
                        ?.quantidadeTreinamento ??
                    0
                ],

                [
                    "Períodos de teste",
                    analise.modelo
                        ?.quantidadeTeste ??
                    0
                ],

                [],

                [
                    "Previsão",
                    analise.previsao
                        ?.referencia ||
                    "-"
                ],

                [
                    "Faturamento previsto",
                    Number(
                        analise.previsao
                            ?.faturamentoPrevisto ||
                        0
                    )
                ],

                [
                    "Tendência",
                    analise.resumo
                        ?.tendencia ||
                    "-"
                ],

                [
                    "Crescimento no período (%)",
                    Number(
                        analise.resumo
                            ?.crescimentoPercentual ||
                        0
                    )
                ],

                [
                    "Média mensal",
                    Number(
                        analise.resumo
                            ?.mediaMensal ||
                        0
                    )
                ],

                [],

                [
                    "MAE",
                    Number(
                        analise.metricas?.mae ||
                        0
                    )
                ],

                [
                    "RMSE",
                    Number(
                        analise.metricas?.rmse ||
                        0
                    )
                ],

                [
                    "R²",
                    Number(
                        analise.metricas?.r2 ||
                        0
                    )
                ],

                [],

                [
                    "Interpretação",
                    analise.interpretacao ||
                    "-"
                ],

                [
                    "Observação",
                    analise.observacao ||
                    analise.descricaoBase ||
                    "-"
                ]
            ];


            const planilhaML =
                XLSX.utils
                    .aoa_to_sheet(
                        dadosMachineLearning
                    );


            planilhaML["!cols"] = [

                {
                    wch: 34
                },

                {
                    wch: 90
                }
            ];


            XLSX.utils
                .book_append_sheet(
                    workbook,
                    planilhaML,
                    "Analise Inteligente"
                );


            /* HISTÓRICO DO MODELO */

            const historicoML =
                (
                    analise.historico ||
                    []
                ).map(
                    item => ({

                        Período:
                            item.periodo,

                        Referência:
                            item.referencia,

                        Ano:
                            item.ano,

                        Mês:
                            item.mes,

                        Faturamento:
                            Number(
                                item.faturamento ||
                                0
                            )
                    })
                );


            historicoML.push({

                Período:
                    "Previsão",

                Referência:
                    analise.previsao
                        ?.referencia ||
                    "-",

                Ano:
                    analise.previsao
                        ?.ano ||
                    "-",

                Mês:
                    analise.previsao
                        ?.mes ||
                    "-",

                Faturamento:
                    Number(
                        analise.previsao
                            ?.faturamentoPrevisto ||
                        0
                    )
            });


            const planilhaHistoricoML =
                XLSX.utils
                    .json_to_sheet(
                        historicoML
                    );


            planilhaHistoricoML["!cols"] = [

                {
                    wch: 14
                },

                {
                    wch: 18
                },

                {
                    wch: 12
                },

                {
                    wch: 12
                },

                {
                    wch: 20
                }
            ];


            XLSX.utils
                .book_append_sheet(
                    workbook,
                    planilhaHistoricoML,
                    "Historico ML"
                );
        }


        /* =================================================
           DOWNLOAD
           ================================================= */

        const hoje =
            new Date();


        const dataArquivo =
            [

                String(
                    hoje.getDate()
                ).padStart(
                    2,
                    "0"
                ),

                String(
                    hoje.getMonth() +
                    1
                ).padStart(
                    2,
                    "0"
                ),

                hoje.getFullYear()

            ].join("-");


        XLSX.writeFile(
            workbook,
            `Relatorio_MoveTech_${dataArquivo}.xlsx`
        );


        mostrarMensagem(
            "Relatório exportado para Excel com sucesso."
        );

    } catch (erro) {

        console.error(erro);

        mostrarMensagem(
            "Não foi possível exportar o relatório.",
            true
        );

    } finally {

        botaoExportar.disabled =
            false;

        botaoExportar.textContent =
            textoOriginal;
    }
}


/* =========================================================
   LOGOUT
   ========================================================= */

function sair() {

    sessionStorage.removeItem(
        "smartmoveis_token"
    );

    sessionStorage.removeItem(
        "smartmoveis_usuario"
    );

    window.location.href =
        "index.html";
}


/* =========================================================
   EVENTOS
   ========================================================= */

if (botaoSair) {

    botaoSair.addEventListener(
        "click",
        sair
    );
}


if (botaoExportar) {

    botaoExportar.addEventListener(
        "click",
        exportarExcel
    );
}


/* =========================================================
   INICIALIZAÇÃO
   ========================================================= */

carregarUsuario();

carregarRelatorios();

carregarAnaliseInteligente();