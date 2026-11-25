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

const tabelaClientes =
    document.getElementById("tabela-clientes");

const buscaCliente =
    document.getElementById("busca-cliente");

const modal =
    document.getElementById("modal-cliente");

const form =
    document.getElementById("form-cliente");

const mensagem =
    document.getElementById("mensagem-clientes");

const mensagemForm =
    document.getElementById("mensagem-form");

const clienteId =
    document.getElementById("cliente-id");

const clienteNome =
    document.getElementById("cliente-nome");

const clienteCpf =
    document.getElementById("cliente-cpf");

const clienteTelefone =
    document.getElementById("cliente-telefone");

const clienteEmail =
    document.getElementById("cliente-email");

const clienteEndereco =
    document.getElementById("cliente-endereco");

const clienteStatus =
    document.getElementById("cliente-status");

const tituloModal =
    document.getElementById("titulo-modal");

let clientes = [];


/* =========================================================
   CARREGAR CLIENTES
   ========================================================= */

async function carregarClientes() {
    esconderMensagem();

    try {
        const resposta = await fetch(
            `${API_URL}/clientes`,
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
                "Erro ao carregar clientes."
            );
        }

        clientes = await resposta.json();

        renderizarClientes(clientes);

    } catch (erro) {
        console.error(erro);

        mostrarMensagem(
            "Não foi possível carregar os clientes."
        );
    }
}


/* =========================================================
   RENDERIZAR CLIENTES
   ========================================================= */

function renderizarClientes(lista) {
    tabelaClientes.innerHTML = "";

    if (!lista.length) {
        tabelaClientes.innerHTML = `
            <tr>
                <td colspan="6">
                    Nenhum cliente encontrado.
                </td>
            </tr>
        `;

        return;
    }

    lista.forEach(cliente => {
        const linha =
            document.createElement("tr");

        linha.innerHTML = `
            <td>
                ${escaparHTML(cliente.nome)}
            </td>

            <td>
                ${escaparHTML(cliente.cpf)}
            </td>

            <td>
                ${escaparHTML(cliente.telefone || "-")}
            </td>

            <td>
                ${escaparHTML(cliente.email || "-")}
            </td>

            <td>
                <span class="status ${
                    cliente.ativo
                        ? "ativo"
                        : "inativo"
                }">
                    ${
                        cliente.ativo
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
                        data-editar="${cliente.id}"
                    >
                        Editar
                    </button>

                    ${
                        cliente.ativo
                            ? `
                                <button
                                    class="botao-acao perigo"
                                    type="button"
                                    data-desativar="${cliente.id}"
                                >
                                    Desativar
                                </button>
                            `
                            : `
                                <button
                                    class="botao-acao"
                                    type="button"
                                    data-reativar="${cliente.id}"
                                >
                                    Reativar
                                </button>
                            `
                    }

                </div>
            </td>
        `;

        tabelaClientes.appendChild(linha);
    });
}


/* =========================================================
   NOVO CLIENTE
   ========================================================= */

function abrirNovoCliente() {
    form.reset();

    clienteId.value = "";
    clienteStatus.value = "true";

    tituloModal.textContent =
        "Novo cliente";

    esconderMensagemForm();

    abrirModal();
}


/* =========================================================
   EDITAR CLIENTE
   ========================================================= */

function abrirEdicao(id) {
    const cliente = clientes.find(
        c => c.id === id
    );

    if (!cliente) {
        return;
    }

    clienteId.value =
        cliente.id;

    clienteNome.value =
        cliente.nome;

    clienteCpf.value =
        cliente.cpf;

    clienteTelefone.value =
        cliente.telefone || "";

    clienteEmail.value =
        cliente.email || "";

    clienteEndereco.value =
        cliente.endereco || "";

    clienteStatus.value =
        String(cliente.ativo);

    tituloModal.textContent =
        "Editar cliente";

    esconderMensagemForm();

    abrirModal();
}


/* =========================================================
   MODAL
   ========================================================= */

function abrirModal() {
    modal.hidden = false;

    modal.setAttribute(
        "aria-hidden",
        "false"
    );

    clienteNome.focus();
}


function fecharModal() {
    modal.hidden = true;

    modal.setAttribute(
        "aria-hidden",
        "true"
    );
}


/* =========================================================
   SALVAR CLIENTE
   ========================================================= */

form.addEventListener(
    "submit",
    async event => {
        event.preventDefault();

        esconderMensagemForm();

        const id =
            clienteId.value;

        const dados = {
            nome:
                clienteNome.value.trim(),

            cpf:
                clienteCpf.value.trim(),

            telefone:
                clienteTelefone.value.trim(),

            email:
                clienteEmail.value.trim(),

            endereco:
                clienteEndereco.value.trim()
        };

        if (id) {
            dados.ativo =
                clienteStatus.value === "true";
        }

        try {
            const resposta = await fetch(
                id
                    ? `${API_URL}/clientes/${id}`
                    : `${API_URL}/clientes`,
                {
                    method: id
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

            if (resposta.status === 401) {
                encerrarSessao();
                return;
            }

            const resultado =
                await lerRespostaJson(resposta);

            if (!resposta.ok) {
                mostrarMensagemForm(
                    resultado.mensagem ||
                    "Não foi possível salvar o cliente."
                );

                return;
            }

            fecharModal();

            await carregarClientes();

        } catch (erro) {
            console.error(erro);

            mostrarMensagemForm(
                "Erro de comunicação com o servidor."
            );
        }
    }
);


/* =========================================================
   DESATIVAR CLIENTE
   ========================================================= */

async function desativarCliente(id) {
    const cliente = clientes.find(
        c => c.id === id
    );

    if (!cliente) {
        return;
    }

    const confirmou = confirm(
        `Deseja desativar o cliente "${cliente.nome}"?`
    );

    if (!confirmou) {
        return;
    }

    esconderMensagem();

    try {
        const resposta = await fetch(
            `${API_URL}/clientes/${id}`,
            {
                method: "DELETE",

                headers: {
                    Authorization:
                        `Bearer ${token}`
                }
            }
        );

        if (resposta.status === 401) {
            encerrarSessao();
            return;
        }

        const resultado =
            await lerRespostaJson(resposta);

        if (!resposta.ok) {
            mostrarMensagem(
                resultado.mensagem ||
                "Não foi possível desativar o cliente."
            );

            return;
        }

        await carregarClientes();

    } catch (erro) {
        console.error(erro);

        mostrarMensagem(
            "Erro de comunicação com o servidor."
        );
    }
}


/* =========================================================
   REATIVAR CLIENTE
   ========================================================= */

async function reativarCliente(id) {
    const cliente = clientes.find(
        c => c.id === id
    );

    if (!cliente) {
        mostrarMensagem(
            "Cliente não encontrado."
        );

        return;
    }

    if (cliente.ativo) {
        return;
    }

    const confirmou = confirm(
        `Deseja reativar o cliente "${cliente.nome}"?`
    );

    if (!confirmou) {
        return;
    }

    esconderMensagem();

    const dados = {
        nome:
            cliente.nome,

        cpf:
            cliente.cpf,

        telefone:
            cliente.telefone || "",

        email:
            cliente.email || "",

        endereco:
            cliente.endereco || "",

        ativo:
            true
    };

    try {
        const resposta = await fetch(
            `${API_URL}/clientes/${id}`,
            {
                method: "PUT",

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

        if (resposta.status === 401) {
            encerrarSessao();
            return;
        }

        const resultado =
            await lerRespostaJson(resposta);

        if (!resposta.ok) {
            mostrarMensagem(
                resultado.mensagem ||
                "Não foi possível reativar o cliente."
            );

            return;
        }

        await carregarClientes();

    } catch (erro) {
        console.error(erro);

        mostrarMensagem(
            "Erro de comunicação com o servidor."
        );
    }
}


/* =========================================================
   BUSCAR CLIENTE
   ========================================================= */

buscaCliente.addEventListener(
    "input",
    () => {
        const termo =
            buscaCliente.value
                .trim()
                .toLowerCase();

        const filtrados =
            clientes.filter(cliente => {
                return (
                    cliente.nome
                        .toLowerCase()
                        .includes(termo) ||

                    cliente.cpf
                        .toLowerCase()
                        .includes(termo) ||

                    (cliente.email || "")
                        .toLowerCase()
                        .includes(termo)
                );
            });

        renderizarClientes(
            filtrados
        );
    }
);


/* =========================================================
   AÇÕES DA TABELA
   ========================================================= */

tabelaClientes.addEventListener(
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

        const reativar =
            event.target.closest(
                "[data-reativar]"
            );


        if (editar) {
            abrirEdicao(
                Number(
                    editar.dataset.editar
                )
            );

            return;
        }


        if (desativar) {
            desativarCliente(
                Number(
                    desativar.dataset.desativar
                )
            );

            return;
        }


        if (reativar) {
            reativarCliente(
                Number(
                    reativar.dataset.reativar
                )
            );
        }
    }
);


/* =========================================================
   BOTÕES
   ========================================================= */

document
    .getElementById(
        "botao-novo-cliente"
    )
    .addEventListener(
        "click",
        abrirNovoCliente
    );


document
    .getElementById(
        "fechar-modal"
    )
    .addEventListener(
        "click",
        fecharModal
    );


document
    .getElementById(
        "cancelar-cliente"
    )
    .addEventListener(
        "click",
        fecharModal
    );


document
    .getElementById(
        "botao-sair"
    )
    .addEventListener(
        "click",
        encerrarSessao
    );


/* =========================================================
   FECHAR MODAL COM ESC
   ========================================================= */

document.addEventListener(
    "keydown",
    event => {
        if (
            event.key === "Escape" &&
            !modal.hidden
        ) {
            fecharModal();
        }
    }
);


/* =========================================================
   LOGOUT
   ========================================================= */

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


/* =========================================================
   RESPOSTA JSON SEGURA
   ========================================================= */

async function lerRespostaJson(
    resposta
) {
    try {
        const texto =
            await resposta.text();

        if (!texto) {
            return {};
        }

        return JSON.parse(texto);

    } catch (erro) {
        console.error(
            "Erro ao interpretar resposta da API:",
            erro
        );

        return {};
    }
}


/* =========================================================
   MENSAGENS
   ========================================================= */

function mostrarMensagem(texto) {
    mensagem.textContent =
        texto;

    mensagem.className =
        "mensagem-clientes erro";

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


/* =========================================================
   SEGURANÇA HTML
   ========================================================= */

function escaparHTML(texto) {
    const div =
        document.createElement("div");

    div.textContent =
        texto ?? "";

    return div.innerHTML;
}


/* =========================================================
   INICIALIZAÇÃO
   ========================================================= */

carregarClientes();