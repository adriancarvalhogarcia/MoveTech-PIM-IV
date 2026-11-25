const API_URL = "http://localhost:5071/api";

const token = sessionStorage.getItem("smartmoveis_token");
const usuarioSalvo = sessionStorage.getItem("smartmoveis_usuario");

if (!token) {
    window.location.href = "index.html";
}

const usuario = usuarioSalvo
    ? JSON.parse(usuarioSalvo)
    : null;

const usuarioNome = document.getElementById("usuario-nome");
const usuarioPerfil = document.getElementById("usuario-perfil");

if (usuario) {
    usuarioNome.textContent = usuario.nome;
    usuarioPerfil.textContent = usuario.perfil;
}

const elementos = {
    totalClientes: document.getElementById("total-clientes"),
    totalProdutos: document.getElementById("total-produtos"),
    totalVendas: document.getElementById("total-vendas"),
    faturamentoTotal: document.getElementById("faturamento-total"),
    ticketMedio: document.getElementById("ticket-medio"),
    totalEstoqueBaixo: document.getElementById("total-estoque-baixo"),

    listaEstoqueBaixo:
        document.getElementById("lista-estoque-baixo"),

    listaProdutosVendidos:
        document.getElementById("lista-produtos-vendidos"),

    tabelaVendas:
        document.getElementById("tabela-vendas"),

    mensagem:
        document.getElementById("mensagem-dashboard")
};

const moedaBRL = new Intl.NumberFormat(
    "pt-BR",
    {
        style: "currency",
        currency: "BRL"
    }
);

const dataBR = new Intl.DateTimeFormat(
    "pt-BR",
    {
        dateStyle: "short",
        timeStyle: "short"
    }
);

async function carregarDashboard() {
    esconderErro();

    try {
        const resposta = await fetch(
            `${API_URL}/relatorios/dashboard`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        if (resposta.status === 401) {
            encerrarSessao();
            return;
        }

        if (!resposta.ok) {
            throw new Error(
                "Não foi possível carregar o dashboard."
            );
        }

        const dados = await resposta.json();

        preencherResumo(dados.resumo);
        preencherEstoqueBaixo(dados.produtosEstoqueBaixo);
        preencherProdutosVendidos(dados.produtosMaisVendidos);
        preencherVendasRecentes(dados.vendasRecentes);

    } catch (erro) {
        console.error(erro);

        mostrarErro(
            "Não foi possível carregar os dados do dashboard."
        );
    }
}

function preencherResumo(resumo) {
    elementos.totalClientes.textContent =
        resumo.totalClientesAtivos;

    elementos.totalProdutos.textContent =
        resumo.totalProdutosAtivos;

    elementos.totalVendas.textContent =
        resumo.totalVendas;

    elementos.faturamentoTotal.textContent =
        moedaBRL.format(resumo.faturamentoTotal);

    elementos.ticketMedio.textContent =
        moedaBRL.format(resumo.ticketMedio);

    elementos.totalEstoqueBaixo.textContent =
        resumo.totalProdutosEstoqueBaixo;
}

function preencherEstoqueBaixo(produtos) {
    elementos.listaEstoqueBaixo.innerHTML = "";

    if (!produtos.length) {
        elementos.listaEstoqueBaixo.innerHTML = `
            <p class="lista-vazia">
                Nenhum produto com estoque baixo.
            </p>
        `;

        return;
    }

    produtos.forEach(produto => {
        const item = document.createElement("div");

        item.className = "lista-item";

        item.innerHTML = `
            <div>
                <strong>${escaparHTML(produto.nome)}</strong>

                <small>
                    Estoque mínimo:
                    ${produto.estoqueMinimo}
                </small>
            </div>

            <span class="lista-valor">
                ${produto.quantidadeEstoque} un.
            </span>
        `;

        elementos.listaEstoqueBaixo.appendChild(item);
    });
}

function preencherProdutosVendidos(produtos) {
    elementos.listaProdutosVendidos.innerHTML = "";

    if (!produtos.length) {
        elementos.listaProdutosVendidos.innerHTML = `
            <p class="lista-vazia">
                Nenhuma venda registrada.
            </p>
        `;

        return;
    }

    produtos.forEach(produto => {
        const item = document.createElement("div");

        item.className = "lista-item";

        item.innerHTML = `
            <div>
                <strong>${escaparHTML(produto.produto)}</strong>

                <small>
                    ${produto.quantidadeVendida}
                    unidade(s) vendida(s)
                </small>
            </div>

            <span class="lista-valor">
                ${moedaBRL.format(produto.faturamento)}
            </span>
        `;

        elementos.listaProdutosVendidos.appendChild(item);
    });
}

function preencherVendasRecentes(vendas) {
    elementos.tabelaVendas.innerHTML = "";

    if (!vendas.length) {
        elementos.tabelaVendas.innerHTML = `
            <tr>
                <td colspan="4">
                    Nenhuma venda registrada.
                </td>
            </tr>
        `;

        return;
    }

    vendas.forEach(venda => {
        const linha = document.createElement("tr");

        linha.innerHTML = `
            <td>#${venda.id}</td>

            <td>
                ${escaparHTML(venda.cliente.nome)}
            </td>

            <td>
                ${moedaBRL.format(venda.valorTotal)}
            </td>

            <td>
                ${dataBR.format(
                    new Date(venda.criadoEm)
                )}
            </td>
        `;

        elementos.tabelaVendas.appendChild(linha);
    });
}

function mostrarErro(texto) {
    elementos.mensagem.textContent = texto;
    elementos.mensagem.hidden = false;
}

function esconderErro() {
    elementos.mensagem.hidden = true;
    elementos.mensagem.textContent = "";
}

function encerrarSessao() {
    sessionStorage.removeItem("smartmoveis_token");
    sessionStorage.removeItem("smartmoveis_usuario");

    window.location.href = "index.html";
}

function escaparHTML(texto) {
    const elemento = document.createElement("div");

    elemento.textContent = texto;

    return elemento.innerHTML;
}

document
    .getElementById("botao-sair")
    .addEventListener(
        "click",
        encerrarSessao
    );

document
    .getElementById("botao-atualizar")
    .addEventListener(
        "click",
        carregarDashboard
    );

carregarDashboard();