const API_URL = "http://localhost:5071/api";

// ==========================================================
// AUTENTICAÇÃO
// ==========================================================

const token = sessionStorage.getItem("smartmoveis_token");
const usuarioSalvo = sessionStorage.getItem("smartmoveis_usuario");

if (!token) {
    window.location.href = "index.html";
}

let usuario = null;

try {
    usuario = usuarioSalvo
        ? JSON.parse(usuarioSalvo)
        : null;
} catch {
    usuario = null;
}


// ==========================================================
// ELEMENTOS DA PÁGINA
// ==========================================================

const nomeUsuario =
    document.getElementById("nomeUsuario");

const btnLogout =
    document.getElementById("btnLogout");

const btnNovaVenda =
    document.getElementById("btnNovaVenda");

const totalVendas =
    document.getElementById("totalVendas");

const totalFaturamento =
    document.getElementById("totalFaturamento");

const ticketMedio =
    document.getElementById("ticketMedio");

const buscarVenda =
    document.getElementById("buscarVenda");

const tabelaVendas =
    document.getElementById("tabelaVendas");

const mensagemVendas =
    document.getElementById("mensagemVendas");


// ==========================================================
// MODAL
// ==========================================================

const modalVenda =
    document.getElementById("modalVenda");

const btnFecharModal =
    document.getElementById("btnFecharModal");

const btnCancelarVenda =
    document.getElementById("btnCancelarVenda");

const formVenda =
    document.getElementById("formVenda");

const clienteVenda =
    document.getElementById("clienteVenda");

const btnAdicionarItem =
    document.getElementById("btnAdicionarItem");

const listaItensVenda =
    document.getElementById("listaItensVenda");

const templateItemVenda =
    document.getElementById("templateItemVenda");

const totalVendaModal =
    document.getElementById("totalVendaModal");

const mensagemModalVenda =
    document.getElementById("mensagemModalVenda");

const btnSalvarVenda =
    document.getElementById("btnSalvarVenda");


// ==========================================================
// DADOS
// ==========================================================

let vendas = [];
let clientes = [];
let produtos = [];


// ==========================================================
// USUÁRIO LOGADO
// ==========================================================

if (usuario && nomeUsuario) {
    nomeUsuario.textContent =
        usuario.nome || "Administrador";
}


// ==========================================================
// FUNÇÕES AUXILIARES
// ==========================================================

function formatarMoeda(valor) {

    const numero = Number(valor) || 0;

    return numero.toLocaleString(
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

    const dataObjeto = new Date(data);

    if (Number.isNaN(dataObjeto.getTime())) {
        return "-";
    }

    return dataObjeto.toLocaleString(
        "pt-BR",
        {
            dateStyle: "short",
            timeStyle: "short"
        }
    );
}


function mostrarMensagem(
    elemento,
    texto,
    tipo = "info"
) {

    if (!elemento) {
        return;
    }

    elemento.textContent = texto;
    elemento.dataset.tipo = tipo;
}


function limparMensagem(elemento) {

    if (!elemento) {
        return;
    }

    elemento.textContent = "";
    elemento.removeAttribute("data-tipo");
}


function encerrarSessao() {

    sessionStorage.removeItem("smartmoveis_token");
    sessionStorage.removeItem("smartmoveis_usuario");

    window.location.href = "index.html";
}


async function requisicao(
    url,
    opcoes = {}
) {

    const headers = {
        ...(opcoes.headers || {}),
        Authorization: `Bearer ${token}`
    };

    if (
        opcoes.body &&
        !headers["Content-Type"]
    ) {
        headers["Content-Type"] =
            "application/json";
    }

    const resposta = await fetch(
        url,
        {
            ...opcoes,
            headers
        }
    );

    if (resposta.status === 401) {

        encerrarSessao();

        throw new Error(
            "Sua sessão expirou."
        );
    }

    return resposta;
}


// ==========================================================
// CARREGAR VENDAS
// ==========================================================

async function carregarVendas() {

    limparMensagem(mensagemVendas);

    if (tabelaVendas) {

        tabelaVendas.innerHTML = `
            <tr>
                <td
                    colspan="6"
                    class="empty-state"
                >
                    Carregando vendas...
                </td>
            </tr>
        `;
    }

    try {

        const resposta = await requisicao(
            `${API_URL}/vendas`
        );

        if (!resposta.ok) {

            let erro = null;

            try {
                erro = await resposta.json();
            } catch {
                erro = null;
            }

            throw new Error(
                erro?.mensagem ||
                "Não foi possível carregar as vendas."
            );
        }

        vendas = await resposta.json();

        if (!Array.isArray(vendas)) {
            vendas = [];
        }

        atualizarIndicadores();
        renderizarVendas(vendas);

    } catch (erro) {

        console.error(
            "Erro ao carregar vendas:",
            erro
        );

        mostrarMensagem(
            mensagemVendas,
            erro.message ||
            "Erro ao carregar vendas.",
            "erro"
        );

        if (tabelaVendas) {

            tabelaVendas.innerHTML = `
                <tr>
                    <td
                        colspan="6"
                        class="empty-state"
                    >
                        Não foi possível carregar as vendas.
                    </td>
                </tr>
            `;
        }
    }
}


// ==========================================================
// INDICADORES
// ==========================================================

function atualizarIndicadores() {

    const quantidade =
        vendas.length;

    const faturamento =
        vendas.reduce(
            (soma, venda) =>
                soma +
                Number(venda.valorTotal || 0) -
                Number(venda.valorDevolvido || 0),
            0
        );

    const media =
        quantidade > 0
            ? faturamento / quantidade
            : 0;

    if (totalVendas) {
        totalVendas.textContent =
            quantidade;
    }

    if (totalFaturamento) {
        totalFaturamento.textContent =
            formatarMoeda(faturamento);
    }

    if (ticketMedio) {
        ticketMedio.textContent =
            formatarMoeda(media);
    }
}


// ==========================================================
// RENDERIZAR HISTÓRICO
// ==========================================================

function renderizarVendas(lista) {

    if (!tabelaVendas) {
        return;
    }

    if (
        !Array.isArray(lista) ||
        lista.length === 0
    ) {

        tabelaVendas.innerHTML = `
            <tr>
                <td
                    colspan="6"
                    class="empty-state"
                >
                    Nenhuma venda encontrada.
                </td>
            </tr>
        `;

        return;
    }

    tabelaVendas.innerHTML =
        lista.map(venda => {

            const quantidadeItens =
                Array.isArray(venda.itens)
                    ? venda.itens.reduce(
                        (soma, item) =>
                            soma +
                            Number(
                                item.quantidade || 0
                            ),
                        0
                    )
                    : 0;

            const nomeCliente =
                venda.cliente?.nome ||
                "Cliente não informado";

            return `
                <tr>

                    <td>
                        <span class="sale-number">
                            #${venda.id}
                        </span>
                    </td>

                    <td>
                        <div class="sale-client">

                            <strong>
                                ${escaparHtml(nomeCliente)}
                            </strong>

                            <span>
                                Cliente #${venda.clienteId}
                            </span>

                        </div>
                    </td>

                    <td>
                        ${formatarData(venda.criadoEm)}
                    </td>

                    <td>
                        ${quantidadeItens}
                    </td>

                    <td>
                        <span class="sale-total">
                            ${formatarMoeda(
                                venda.valorTotal
                            )}
                        </span>

                        ${window.MT ? `<br><span class="texto-fraco">${
                            MT.escapar(MT.nomeForma(venda.formaPagamento))
                        }${
                            venda.parcelas > 1 ? ` · ${venda.parcelas}x` : ""
                        }</span>` : ""}

                        ${venda.status === "Devolvida"
                            ? '<br><span class="badge badge-vencida">Devolvida</span>'
                            : venda.status === "DevolvidaParcial"
                                ? `<br><span class="badge badge-alerta">Devolução parcial (${formatarMoeda(venda.valorDevolvido)})</span>`
                                : ""}
                    </td>

                    <td>

                        <button
                            type="button"
                            class="details-button"
                            data-venda-id="${venda.id}"
                        >
                            Detalhes
                        </button>

                    </td>

                </tr>
            `;
        }).join("");
}


// ==========================================================
// PROTEÇÃO DE TEXTO HTML
// ==========================================================

function escaparHtml(valor) {

    const elemento =
        document.createElement("div");

    elemento.textContent =
        String(valor ?? "");

    return elemento.innerHTML;
}


// ==========================================================
// BUSCAR VENDA
// ==========================================================

function filtrarVendas() {

    if (!buscarVenda) {
        return;
    }

    const termo =
        buscarVenda.value
            .trim()
            .toLowerCase();

    if (!termo) {

        renderizarVendas(vendas);

        return;
    }

    const resultado =
        vendas.filter(venda => {

            const cliente =
                venda.cliente?.nome
                    ?.toLowerCase() || "";

            const numero =
                String(venda.id);

            return (
                cliente.includes(termo) ||
                numero.includes(termo)
            );
        });

    renderizarVendas(resultado);
}


// ==========================================================
// CARREGAR CLIENTES
// ==========================================================

async function carregarClientes() {

    const resposta = await requisicao(
        `${API_URL}/clientes`
    );

    if (!resposta.ok) {

        throw new Error(
            "Não foi possível carregar os clientes."
        );
    }

    const dados =
        await resposta.json();

    clientes =
        Array.isArray(dados)
            ? dados.filter(
                cliente =>
                    cliente.ativo === true
            )
            : [];

    preencherClientes();
}


function preencherClientes() {

    if (!clienteVenda) {
        return;
    }

    clienteVenda.innerHTML = `
        <option value="">
            Selecione um cliente
        </option>
    `;

    clientes.forEach(cliente => {

        const option =
            document.createElement("option");

        option.value =
            cliente.id;

        option.textContent =
            cliente.nome;

        clienteVenda.appendChild(option);
    });
}


// ==========================================================
// CARREGAR PRODUTOS
// ==========================================================

async function carregarProdutos() {

    const resposta = await requisicao(
        `${API_URL}/produtos`
    );

    if (!resposta.ok) {

        throw new Error(
            "Não foi possível carregar os produtos."
        );
    }

    const dados =
        await resposta.json();

    produtos =
        Array.isArray(dados)
            ? dados.filter(
                produto =>
                    produto.ativo === true
            )
            : [];
}


// ==========================================================
// ABRIR MODAL
// ==========================================================

async function abrirModalVenda() {

    limparMensagem(
        mensagemModalVenda
    );

    if (!modalVenda) {
        return;
    }

    try {

        await Promise.all([
            carregarClientes(),
            carregarProdutos()
        ]);

        if (clientes.length === 0) {

            mostrarMensagem(
                mensagemVendas,
                "Não existem clientes ativos para registrar uma venda.",
                "erro"
            );

            return;
        }

        if (produtos.length === 0) {

            mostrarMensagem(
                mensagemVendas,
                "Não existem produtos ativos para registrar uma venda.",
                "erro"
            );

            return;
        }

        if (formVenda) {
            formVenda.reset();
        }

        if (listaItensVenda) {
            listaItensVenda.innerHTML = "";
        }

        adicionarItemVenda();

        atualizarTotalModal();

        modalVenda.hidden = false;

        modalVenda.setAttribute(
            "aria-hidden",
            "false"
        );

        document.body.style.overflow =
            "hidden";

        setTimeout(() => {
            clienteVenda?.focus();
        }, 50);

    } catch (erro) {

        console.error(
            "Erro ao abrir venda:",
            erro
        );

        mostrarMensagem(
            mensagemVendas,
            erro.message ||
            "Não foi possível iniciar a venda.",
            "erro"
        );
    }
}


// ==========================================================
// FECHAR MODAL
// ==========================================================

function fecharModalVenda() {

    if (!modalVenda) {
        return;
    }

    modalVenda.hidden = true;

    modalVenda.setAttribute(
        "aria-hidden",
        "true"
    );

    document.body.style.overflow = "";

    if (listaItensVenda) {
        listaItensVenda.innerHTML = "";
    }

    limparMensagem(
        mensagemModalVenda
    );

    btnNovaVenda?.focus();
}


// ==========================================================
// ADICIONAR ITEM
// ==========================================================

function adicionarItemVenda() {

    if (
        !templateItemVenda ||
        !listaItensVenda
    ) {
        return;
    }

    const fragmento =
        templateItemVenda.content
            .cloneNode(true);

    const item =
        fragmento.querySelector(
            ".sale-item"
        );

    const selectProduto =
        fragmento.querySelector(
            ".produto-item"
        );

    const quantidade =
        fragmento.querySelector(
            ".quantidade-item"
        );

    const estoque =
        fragmento.querySelector(
            ".item-stock"
        );

    const subtotal =
        fragmento.querySelector(
            ".item-subtotal"
        );

    const remover =
        fragmento.querySelector(
            ".remove-item-button"
        );


    // PRODUTOS

    produtos.forEach(produto => {

        const option =
            document.createElement("option");

        option.value =
            produto.id;

        option.textContent =
            `${produto.nome} - ${formatarMoeda(
                produto.preco
            )}`;

        selectProduto.appendChild(option);
    });


    // ALTERAÇÃO DE PRODUTO

    selectProduto.addEventListener(
        "change",
        () => {

            atualizarItem(
                item,
                selectProduto,
                quantidade,
                estoque,
                subtotal
            );
        }
    );


    // ALTERAÇÃO DE QUANTIDADE

    quantidade.addEventListener(
        "input",
        () => {

            atualizarItem(
                item,
                selectProduto,
                quantidade,
                estoque,
                subtotal
            );
        }
    );


    // REMOVER ITEM

    remover.addEventListener(
        "click",
        () => {

            item.remove();

            atualizarTotalModal();
        }
    );


    listaItensVenda.appendChild(
        fragmento
    );
}


// ==========================================================
// ATUALIZAR ITEM
// ==========================================================

function atualizarItem(
    item,
    selectProduto,
    inputQuantidade,
    estoqueElemento,
    subtotalElemento
) {

    const produtoId =
        Number(selectProduto.value);

    const produto =
        produtos.find(
            p =>
                Number(p.id) === produtoId
        );

    if (!produto) {

        estoqueElemento.textContent =
            "Estoque: -";

        subtotalElemento.textContent =
            formatarMoeda(0);

        item.dataset.subtotal = "0";

        atualizarTotalModal();

        return;
    }

    let quantidade =
        Number(inputQuantidade.value);

    if (
        !Number.isInteger(quantidade) ||
        quantidade < 1
    ) {
        quantidade = 1;
    }

    const estoqueDisponivel =
        Number(
            produto.quantidadeEstoque || 0
        );

    estoqueElemento.textContent =
        `Estoque: ${estoqueDisponivel}`;

    if (
        quantidade >
        estoqueDisponivel
    ) {

        estoqueElemento.textContent =
            `Estoque: ${estoqueDisponivel} — quantidade indisponível`;

        estoqueElemento.style.color =
            "#ff7d7d";

    } else {

        estoqueElemento.style.color = "";
    }

    const subtotal =
        Number(produto.preco || 0) *
        quantidade;

    subtotalElemento.textContent =
        formatarMoeda(subtotal);

    item.dataset.subtotal =
        String(subtotal);

    atualizarTotalModal();
}


// ==========================================================
// TOTAL DO MODAL
// ==========================================================

function atualizarTotalModal() {

    if (!totalVendaModal) {
        return;
    }

    const itens =
        listaItensVenda
            ?.querySelectorAll(
                ".sale-item"
            ) || [];

    let total = 0;

    itens.forEach(item => {

        total +=
            Number(
                item.dataset.subtotal || 0
            );
    });

    totalVendaModal.textContent =
        formatarMoeda(total);
}


// ==========================================================
// MONTAR DADOS DA VENDA
// ==========================================================

function montarVenda() {

    const clienteId =
        Number(clienteVenda.value);

    if (!clienteId) {

        throw new Error(
            "Selecione um cliente."
        );
    }

    const elementosItens =
        Array.from(
            listaItensVenda.querySelectorAll(
                ".sale-item"
            )
        );

    if (elementosItens.length === 0) {

        throw new Error(
            "Adicione pelo menos um produto."
        );
    }

    const itens = [];

    for (
        const elemento of elementosItens
    ) {

        const select =
            elemento.querySelector(
                ".produto-item"
            );

        const input =
            elemento.querySelector(
                ".quantidade-item"
            );

        const produtoId =
            Number(select.value);

        const quantidade =
            Number(input.value);

        if (!produtoId) {

            throw new Error(
                "Selecione o produto de todos os itens."
            );
        }

        if (
            !Number.isInteger(quantidade) ||
            quantidade < 1
        ) {

            throw new Error(
                "Informe uma quantidade válida."
            );
        }

        const produto =
            produtos.find(
                p =>
                    Number(p.id) === produtoId
            );

        if (!produto) {

            throw new Error(
                "Produto selecionado não foi encontrado."
            );
        }

        if (
            quantidade >
            Number(
                produto.quantidadeEstoque || 0
            )
        ) {

            throw new Error(
                `Estoque insuficiente para ${produto.nome}.`
            );
        }

        itens.push({
            produtoId,
            quantidade
        });
    }

    // Pagamento: define as contas a receber geradas pela venda.
    const formaPagamento =
        document.getElementById("formaPagamentoVenda")?.value;

    if (!formaPagamento) {

        throw new Error(
            "Selecione a forma de pagamento."
        );
    }

    const parcelas =
        Number(
            document.getElementById("parcelasVenda")?.value || 1
        );

    return {
        clienteId,
        itens,
        formaPagamento,
        parcelas
    };
}


// ==========================================================
// SALVAR VENDA
// ==========================================================

async function salvarVenda(evento) {

    evento.preventDefault();

    limparMensagem(
        mensagemModalVenda
    );

    try {

        const venda =
            montarVenda();

        if (btnSalvarVenda) {

            btnSalvarVenda.disabled =
                true;

            btnSalvarVenda.textContent =
                "Finalizando...";
        }

        const resposta =
            await requisicao(
                `${API_URL}/vendas`,
                {
                    method: "POST",

                    body: JSON.stringify(
                        venda
                    )
                }
            );

        let dados = null;

        try {
            dados = await resposta.json();
        } catch {
            dados = null;
        }

        if (!resposta.ok) {

            throw new Error(
                dados?.mensagem ||
                "Não foi possível registrar a venda."
            );
        }

        fecharModalVenda();

        mostrarMensagem(
            mensagemVendas,
            `Venda #${dados?.id || ""} registrada com sucesso.`,
            "sucesso"
        );

        await carregarVendas();

    } catch (erro) {

        console.error(
            "Erro ao registrar venda:",
            erro
        );

        mostrarMensagem(
            mensagemModalVenda,
            erro.message ||
            "Erro ao registrar a venda.",
            "erro"
        );

    } finally {

        if (btnSalvarVenda) {

            btnSalvarVenda.disabled =
                false;

            btnSalvarVenda.textContent =
                "Finalizar venda";
        }
    }
}


// ==========================================================
// DETALHES DA VENDA
// ==========================================================

function mostrarDetalhesVenda(id) {

    // PIM IV: detalhes com devolução (vendas-detalhe.js).
    if (typeof window.abrirDetalheVenda === "function") {
        window.abrirDetalheVenda(Number(id));
        return;
    }

    const venda =
        vendas.find(
            item =>
                Number(item.id) ===
                Number(id)
        );

    if (!venda) {
        return;
    }

    const itens =
        Array.isArray(venda.itens)
            ? venda.itens
            : [];

    const descricaoItens =
        itens.length > 0
            ? itens
                .map(item => {

                    const produto =
                        item.produto?.nome ||
                        `Produto #${item.produtoId}`;

                    return (
                        `${produto} — ` +
                        `${item.quantidade} un. — ` +
                        `${formatarMoeda(
                            item.subtotal
                        )}`
                    );
                })
                .join("\n")
            : "Nenhum item informado.";

    window.alert(
        `Venda #${venda.id}\n\n` +
        `Cliente: ${
            venda.cliente?.nome || "-"
        }\n` +
        `Data: ${
            formatarData(
                venda.criadoEm
            )
        }\n` +
        `Total: ${
            formatarMoeda(
                venda.valorTotal
            )
        }\n\n` +
        `Itens:\n${descricaoItens}`
    );
}


// ==========================================================
// EVENTOS
// ==========================================================

btnLogout?.addEventListener(
    "click",
    encerrarSessao
);


btnNovaVenda?.addEventListener(
    "click",
    abrirModalVenda
);


btnFecharModal?.addEventListener(
    "click",
    fecharModalVenda
);


btnCancelarVenda?.addEventListener(
    "click",
    fecharModalVenda
);


btnAdicionarItem?.addEventListener(
    "click",
    adicionarItemVenda
);


formVenda?.addEventListener(
    "submit",
    salvarVenda
);


buscarVenda?.addEventListener(
    "input",
    filtrarVendas
);


tabelaVendas?.addEventListener(
    "click",
    evento => {

        const botao =
            evento.target.closest(
                ".details-button"
            );

        if (!botao) {
            return;
        }

        mostrarDetalhesVenda(
            botao.dataset.vendaId
        );
    }
);


// FECHAR CLICANDO FORA DO MODAL

modalVenda?.addEventListener(
    "click",
    evento => {

        if (
            evento.target ===
            modalVenda
        ) {
            fecharModalVenda();
        }
    }
);


// FECHAR COM ESC

document.addEventListener(
    "keydown",
    evento => {

        if (
            evento.key === "Escape" &&
            modalVenda &&
            !modalVenda.hidden
        ) {
            fecharModalVenda();
        }
    }
);


// ==========================================================
// INICIALIZAÇÃO
// ==========================================================

carregarVendas();