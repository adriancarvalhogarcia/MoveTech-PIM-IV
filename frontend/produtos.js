const API_URL = "http://localhost:5071/api";

const token = sessionStorage.getItem("smartmoveis_token");
const usuarioSalvo = sessionStorage.getItem("smartmoveis_usuario");

if (!token) {
    window.location.href = "index.html";
}

const usuario = usuarioSalvo
    ? JSON.parse(usuarioSalvo)
    : null;

if (usuario) {
    document.getElementById("usuario-nome").textContent =
        usuario.nome;

    document.getElementById("usuario-perfil").textContent =
        usuario.perfil;
}

const tabelaProdutos =
    document.getElementById("tabela-produtos");

const buscaProduto =
    document.getElementById("busca-produto");

const modal =
    document.getElementById("modal-produto");

const form =
    document.getElementById("form-produto");

const mensagem =
    document.getElementById("mensagem-produtos");

const mensagemForm =
    document.getElementById("mensagem-form-produto");

const produtoId =
    document.getElementById("produto-id");

const produtoNome =
    document.getElementById("produto-nome");

const produtoDescricao =
    document.getElementById("produto-descricao");

const produtoCategoria =
    document.getElementById("produto-categoria");

const produtoPreco =
    document.getElementById("produto-preco");

const produtoEstoque =
    document.getElementById("produto-estoque");

const produtoEstoqueMinimo =
    document.getElementById("produto-estoque-minimo");

const produtoStatus =
    document.getElementById("produto-status");

const tituloModal =
    document.getElementById("titulo-modal-produto");

const resumoTotal =
    document.getElementById("resumo-total-produtos");

const resumoAtivos =
    document.getElementById("resumo-produtos-ativos");

const resumoEstoqueBaixo =
    document.getElementById("resumo-estoque-baixo");

const moedaBRL = new Intl.NumberFormat(
    "pt-BR",
    {
        style: "currency",
        currency: "BRL"
    }
);

let produtos = [];

async function carregarProdutos() {
    esconderMensagem();

    try {
        const resposta = await fetch(
            `${API_URL}/produtos`,
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
                "Erro ao carregar produtos."
            );
        }

        produtos = await resposta.json();

        renderizarProdutos(produtos);
        atualizarResumo();

    } catch (erro) {
        console.error(erro);

        mostrarMensagem(
            "Não foi possível carregar os produtos."
        );
    }
}

function renderizarProdutos(lista) {
    tabelaProdutos.innerHTML = "";

    if (!lista.length) {
        tabelaProdutos.innerHTML = `
            <tr>
                <td colspan="7">
                    Nenhum produto encontrado.
                </td>
            </tr>
        `;

        return;
    }

    lista.forEach(produto => {
        const linha = document.createElement("tr");

        const estoqueBaixo =
            produto.ativo &&
            produto.quantidadeEstoque <=
            produto.estoqueMinimo;

        linha.innerHTML = `
            <td>
                <strong>
                    ${escaparHTML(produto.nome)}
                </strong>

                ${
                    produto.descricao
                        ? `
                            <small class="produto-descricao">
                                ${escaparHTML(produto.descricao)}
                            </small>
                        `
                        : ""
                }
            </td>

            <td>
                ${escaparHTML(produto.categoria)}
            </td>

            <td>
                ${moedaBRL.format(produto.preco)}
            </td>

            <td class="${
                estoqueBaixo
                    ? "estoque-baixo"
                    : "estoque-normal"
            }">
                ${
                    estoqueBaixo
                        ? "⚠️ "
                        : ""
                }

                ${produto.quantidadeEstoque}
            </td>

            <td>
                ${produto.estoqueMinimo}
            </td>

            <td>
                <span class="status ${
                    produto.ativo
                        ? "ativo"
                        : "inativo"
                }">
                    ${
                        produto.ativo
                            ? "Ativo"
                            : "Inativo"
                    }
                </span>
            </td>

            <td>
                <div class="acoes">

                    <button
                        class="botao-acao"
                        type="button"
                        data-editar="${produto.id}"
                    >
                        Editar
                    </button>

                    ${
                        produto.ativo
                            ? `
                                <button
                                    class="botao-acao perigo"
                                    type="button"
                                    data-desativar="${produto.id}"
                                >
                                    Desativar
                                </button>
                            `
                            : ""
                    }

                </div>
            </td>
        `;

        tabelaProdutos.appendChild(linha);
    });
}

function atualizarResumo() {
    const total =
        produtos.length;

    const ativos =
        produtos.filter(
            p => p.ativo
        ).length;

    const estoqueBaixo =
        produtos.filter(
            p =>
                p.ativo &&
                p.quantidadeEstoque <=
                p.estoqueMinimo
        ).length;

    resumoTotal.textContent =
        total;

    resumoAtivos.textContent =
        ativos;

    resumoEstoqueBaixo.textContent =
        estoqueBaixo;
}

function abrirNovoProduto() {
    form.reset();

    produtoId.value = "";
    produtoStatus.value = "true";

    tituloModal.textContent =
        "Novo produto";

    esconderMensagemForm();
    abrirModal();
}

function abrirEdicao(id) {
    const produto = produtos.find(
        p => p.id === id
    );

    if (!produto) {
        return;
    }

    produtoId.value =
        produto.id;

    produtoNome.value =
        produto.nome;

    produtoDescricao.value =
        produto.descricao || "";

    produtoCategoria.value =
        produto.categoria;

    produtoPreco.value =
        produto.preco;

    produtoEstoque.value =
        produto.quantidadeEstoque;

    produtoEstoqueMinimo.value =
        produto.estoqueMinimo;

    produtoStatus.value =
        String(produto.ativo);

    tituloModal.textContent =
        "Editar produto";

    esconderMensagemForm();
    abrirModal();
}

function abrirModal() {
    modal.hidden = false;

    modal.setAttribute(
        "aria-hidden",
        "false"
    );

    produtoNome.focus();
}

function fecharModal() {
    modal.hidden = true;

    modal.setAttribute(
        "aria-hidden",
        "true"
    );
}

form.addEventListener(
    "submit",
    async event => {
        event.preventDefault();

        esconderMensagemForm();

        const id =
            produtoId.value;

        const dados = {
            nome:
                produtoNome.value.trim(),

            descricao:
                produtoDescricao.value.trim(),

            categoria:
                produtoCategoria.value.trim(),

            preco:
                Number(produtoPreco.value),

            quantidadeEstoque:
                Number(produtoEstoque.value),

            estoqueMinimo:
                Number(produtoEstoqueMinimo.value)
        };

        if (id) {
            dados.ativo =
                produtoStatus.value === "true";
        }

        try {
            const resposta = await fetch(
                id
                    ? `${API_URL}/produtos/${id}`
                    : `${API_URL}/produtos`,
                {
                    method:
                        id
                            ? "PUT"
                            : "POST",

                    headers: {
                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`
                    },

                    body:
                        JSON.stringify(dados)
                }
            );

            const resultado =
                await resposta.json();

            if (!resposta.ok) {
                mostrarMensagemForm(
                    resultado.mensagem ||
                    "Não foi possível salvar o produto."
                );

                return;
            }

            fecharModal();

            await carregarProdutos();

        } catch (erro) {
            console.error(erro);

            mostrarMensagemForm(
                "Erro de comunicação com o servidor."
            );
        }
    }
);

async function desativarProduto(id) {
    const produto = produtos.find(
        p => p.id === id
    );

    if (!produto) {
        return;
    }

    const confirmou = confirm(
        `Deseja desativar o produto "${produto.nome}"?`
    );

    if (!confirmou) {
        return;
    }

    try {
        const resposta = await fetch(
            `${API_URL}/produtos/${id}`,
            {
                method: "DELETE",

                headers: {
                    Authorization:
                        `Bearer ${token}`
                }
            }
        );

        const resultado =
            await resposta.json();

        if (!resposta.ok) {
            mostrarMensagem(
                resultado.mensagem ||
                "Não foi possível desativar o produto."
            );

            return;
        }

        await carregarProdutos();

    } catch (erro) {
        console.error(erro);

        mostrarMensagem(
            "Erro de comunicação com o servidor."
        );
    }
}

buscaProduto.addEventListener(
    "input",
    () => {
        const termo =
            buscaProduto.value
                .trim()
                .toLowerCase();

        const filtrados =
            produtos.filter(
                produto => {
                    return (
                        produto.nome
                            .toLowerCase()
                            .includes(termo)
                        ||
                        produto.categoria
                            .toLowerCase()
                            .includes(termo)
                    );
                }
            );

        renderizarProdutos(
            filtrados
        );
    }
);

tabelaProdutos.addEventListener(
    "click",
    event => {
        const editar =
            event.target.closest(
                "[data-editar]"
            );

        const desativar =
            event.target.closest(
                "[data-desativar]"
            );

        if (editar) {
            abrirEdicao(
                Number(
                    editar.dataset.editar
                )
            );
        }

        if (desativar) {
            desativarProduto(
                Number(
                    desativar.dataset.desativar
                )
            );
        }
    }
);

document
    .getElementById("botao-novo-produto")
    .addEventListener(
        "click",
        abrirNovoProduto
    );

document
    .getElementById("fechar-modal-produto")
    .addEventListener(
        "click",
        fecharModal
    );

document
    .getElementById("cancelar-produto")
    .addEventListener(
        "click",
        fecharModal
    );

document
    .getElementById("botao-sair")
    .addEventListener(
        "click",
        encerrarSessao
    );

function encerrarSessao() {
    sessionStorage.removeItem(
        "smartmoveis_token"
    );

    sessionStorage.removeItem(
        "smartmoveis_usuario"
    );

    window.location.href =
        "index.html";
}

function mostrarMensagem(texto) {
    mensagem.textContent =
        texto;

    mensagem.className =
        "mensagem-produtos erro";

    mensagem.hidden =
        false;
}

function esconderMensagem() {
    mensagem.hidden =
        true;

    mensagem.textContent =
        "";
}

function mostrarMensagemForm(texto) {
    mensagemForm.textContent =
        texto;

    mensagemForm.className =
        "mensagem-form erro";

    mensagemForm.hidden =
        false;
}

function esconderMensagemForm() {
    mensagemForm.hidden =
        true;

    mensagemForm.textContent =
        "";
}

function escaparHTML(texto) {
    const div =
        document.createElement("div");

    div.textContent =
        texto ?? "";

    return div.innerHTML;
}

carregarProdutos();