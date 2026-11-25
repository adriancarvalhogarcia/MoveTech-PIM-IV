const API_URL = "http://localhost:5071/api";

/* =========================================================
   ELEMENTOS DO LOGIN
========================================================= */

const form = document.getElementById("login-form");
const emailInput = document.getElementById("email");
const senhaInput = document.getElementById("senha");
const mensagem = document.getElementById("mensagem");
const botaoLogin = document.getElementById("botao-login");
const textoBotaoLogin = botaoLogin?.querySelector("span");
const mostrarSenha = document.getElementById("mostrar-senha");
const mostrarSenhaIcon = document.getElementById("mostrar-senha-icon");
const esqueceuSenha = document.getElementById("esqueceu-senha");

/* =========================================================
   ELEMENTOS DO MODAL
========================================================= */

const featureButtons = document.querySelectorAll(".feature-card-button");
const featureModal = document.getElementById("feature-modal");
const modalCard = featureModal?.querySelector(".modal-card");
const modalClose = document.getElementById("modal-close");
const modalActionClose = document.getElementById("modal-action-close");
const modalIcon = document.getElementById("modal-icon");
const modalTitle = document.getElementById("modal-title");
const modalDescription = document.getElementById("modal-description");
const modalResourcesList = document.getElementById("modal-resources-list");

let ultimoElementoFocado = null;

/* =========================================================
   CONTEÚDO DOS CARDS
========================================================= */

const recursosMoveTech = {
    "1": {
        titulo: "Gestão de clientes",

        descricao:
            "Centralize as informações dos seus clientes e mantenha seus relacionamentos organizados. O MoveTech permite cadastrar, consultar, atualizar e gerenciar clientes em um único ambiente.",

        recursos: [
            "Cadastro de clientes",
            "Consulta e pesquisa",
            "Atualização de informações",
            "Organização dos registros"
        ],

        icone: `
            <svg viewBox="0 0 24 24">
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M2 21v-2a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v2"></path>
                <path d="M17 4.5a4 4 0 0 1 0 7"></path>
                <path d="M22 21v-2a5 5 0 0 0-3-4.6"></path>
            </svg>
        `
    },

    "2": {
        titulo: "Controle de estoque",

        descricao:
            "Acompanhe a disponibilidade dos produtos e tenha maior controle sobre o estoque da empresa.",

        recursos: [
            "Consulta de estoque",
            "Identificação de estoque baixo",
            "Controle de quantidades",
            "Integração com produtos e vendas"
        ],

        icone: `
            <svg viewBox="0 0 24 24">
                <path d="m21 8-9-5-9 5 9 5 9-5Z"></path>
                <path d="M3 8v9l9 5 9-5V8"></path>
                <path d="M12 13v9"></path>
            </svg>
        `
    },

    "3": {
        titulo: "Cadastro de produtos",

        descricao:
            "Organize o catálogo de produtos da empresa com informações centralizadas e disponíveis para os demais módulos do sistema.",

        recursos: [
            "Cadastro de produtos",
            "Edição e consulta",
            "Controle de preços",
            "Controle de estoque"
        ],

        icone: `
            <svg viewBox="0 0 24 24">
                <rect x="3" y="4" width="18" height="16" rx="2"></rect>
                <path d="M8 4v16"></path>
                <path d="M13 8h5"></path>
                <path d="M13 12h5"></path>
                <path d="M13 16h3"></path>
            </svg>
        `
    },

    "4": {
        titulo: "Vendas e relatórios",

        descricao:
            "Registre vendas e transforme os dados operacionais em informações úteis para acompanhamento do negócio.",

        recursos: [
            "Registro de vendas",
            "Histórico de operações",
            "Indicadores",
            "Relatórios gerenciais"
        ],

        icone: `
            <svg viewBox="0 0 24 24">
                <path d="M4 20V11h4v9"></path>
                <path d="M10 20V6h4v14"></path>
                <path d="M16 20V3h4v17"></path>
                <path d="M2 20h20"></path>
            </svg>
        `
    }
};


/* =========================================================
   MOSTRAR / OCULTAR SENHA
========================================================= */

if (mostrarSenha && senhaInput) {

    mostrarSenha.addEventListener("click", () => {

        const estaVisivel =
            senhaInput.type === "text";

        senhaInput.type =
            estaVisivel
                ? "password"
                : "text";

        mostrarSenha.setAttribute(
            "aria-pressed",
            String(!estaVisivel)
        );

        mostrarSenha.setAttribute(
            "aria-label",
            estaVisivel
                ? "Mostrar senha"
                : "Ocultar senha"
        );

        if (mostrarSenhaIcon) {

            if (estaVisivel) {

                mostrarSenhaIcon.innerHTML = `
                    <path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"></path>
                    <circle
                        cx="12"
                        cy="12"
                        r="2.5"
                    ></circle>
                `;

            } else {

                mostrarSenhaIcon.innerHTML = `
                    <path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"></path>

                    <circle
                        cx="12"
                        cy="12"
                        r="2.5"
                    ></circle>

                    <path
                        d="M4 4l16 16"
                    ></path>
                `;
            }
        }
    });
}


/* =========================================================
   LOGIN
========================================================= */

if (
    form &&
    emailInput &&
    senhaInput &&
    botaoLogin
) {

    form.addEventListener(
        "submit",
        async (event) => {

            event.preventDefault();

            esconderMensagem();

            const email =
                emailInput.value.trim();

            const senha =
                senhaInput.value;

            if (!email || !senha) {

                mostrarErro(
                    "Preencha o e-mail e a senha para continuar."
                );

                return;
            }

            botaoLogin.disabled = true;

            if (textoBotaoLogin) {

                textoBotaoLogin.textContent =
                    "Entrando...";
            }

            try {

                const resposta =
                    await fetch(
                        `${API_URL}/auth/login`,
                        {
                            method: "POST",

                            headers: {
                                "Content-Type":
                                    "application/json"
                            },

                            body: JSON.stringify({
                                email: email,
                                senha: senha
                            })
                        }
                    );


                let dados = {};

                try {

                    dados =
                        await resposta.json();

                } catch {

                    dados = {};
                }


                if (!resposta.ok) {

                    mostrarErro(
                        dados.mensagem ||
                        "E-mail ou senha inválidos."
                    );

                    return;
                }


                if (
                    !dados.token ||
                    !dados.usuario
                ) {

                    mostrarErro(
                        "O servidor retornou uma resposta de login inválida."
                    );

                    return;
                }


                sessionStorage.setItem(
                    "smartmoveis_token",
                    dados.token
                );


                sessionStorage.setItem(
                    "smartmoveis_usuario",
                    JSON.stringify(
                        dados.usuario
                    )
                );


                window.location.href =
                    "dashboard.html";

            } catch (erro) {

                console.error(
                    "Erro ao realizar login:",
                    erro
                );

                mostrarErro(
                    "Não foi possível conectar ao servidor. Verifique se a API está em execução."
                );

            } finally {

                botaoLogin.disabled = false;

                if (textoBotaoLogin) {

                    textoBotaoLogin.textContent =
                        "Entrar";
                }
            }
        }
    );
}


/* =========================================================
   MENSAGENS
========================================================= */

function mostrarErro(texto) {

    if (!mensagem) {
        return;
    }

    mensagem.textContent = texto;

    mensagem.className =
        "mensagem erro";

    mensagem.hidden = false;
}


function mostrarInformacao(texto) {

    if (!mensagem) {
        return;
    }

    mensagem.textContent = texto;

    mensagem.className =
        "mensagem sucesso";

    mensagem.hidden = false;
}


function esconderMensagem() {

    if (!mensagem) {
        return;
    }

    mensagem.hidden = true;

    mensagem.textContent = "";

    mensagem.className =
        "mensagem";
}


/* =========================================================
   MODAL DOS QUATRO RECURSOS
========================================================= */

featureButtons.forEach(
    (botao) => {

        botao.addEventListener(
            "click",
            () => {

                abrirModalRecurso(
                    botao.dataset.feature,
                    botao
                );
            }
        );
    }
);


function abrirModalRecurso(
    idRecurso,
    elementoOrigem
) {

    if (
        !featureModal ||
        !modalCard ||
        !modalTitle ||
        !modalDescription ||
        !modalResourcesList ||
        !modalIcon
    ) {
        return;
    }


    const recurso =
        recursosMoveTech[idRecurso];


    if (!recurso) {
        return;
    }


    ultimoElementoFocado =
        elementoOrigem ||
        document.activeElement;


    modalTitle.textContent =
        recurso.titulo;


    modalDescription.textContent =
        recurso.descricao;


    modalIcon.innerHTML =
        recurso.icone;


    modalResourcesList.innerHTML =
        "";


    recurso.recursos.forEach(
        (texto) => {

            const item =
                document.createElement("li");

            item.textContent =
                texto;

            modalResourcesList.appendChild(
                item
            );
        }
    );


    featureModal.hidden = false;

    document.body.classList.add(
        "modal-open"
    );


    requestAnimationFrame(
        () => {

            if (modalClose) {

                modalClose.focus();

            } else {

                modalCard.focus();
            }
        }
    );
}


function fecharModalRecurso() {

    if (
        !featureModal ||
        featureModal.hidden
    ) {
        return;
    }


    featureModal.hidden = true;


    document.body.classList.remove(
        "modal-open"
    );


    if (
        ultimoElementoFocado &&
        typeof ultimoElementoFocado.focus
            === "function"
    ) {

        ultimoElementoFocado.focus();
    }


    ultimoElementoFocado = null;
}


/* =========================================================
   BOTÃO X DO MODAL
========================================================= */

if (modalClose) {

    modalClose.addEventListener(
        "click",
        fecharModalRecurso
    );
}


/* =========================================================
   BOTÃO "ENTENDI"
========================================================= */

if (modalActionClose) {

    modalActionClose.addEventListener(
        "click",
        fecharModalRecurso
    );
}


/* =========================================================
   CLIQUE FORA DO MODAL
========================================================= */

if (featureModal) {

    featureModal.addEventListener(
        "click",
        (event) => {

            if (
                event.target ===
                featureModal
            ) {

                fecharModalRecurso();
            }
        }
    );
}


/* =========================================================
   ESC + CONTROLE DE FOCO
========================================================= */

document.addEventListener(
    "keydown",
    (event) => {

        if (
            !featureModal ||
            featureModal.hidden
        ) {
            return;
        }


        if (event.key === "Escape") {

            event.preventDefault();

            fecharModalRecurso();

            return;
        }


        if (event.key === "Tab") {

            manterFocoDentroDoModal(
                event
            );
        }
    }
);


function manterFocoDentroDoModal(
    event
) {

    if (
        !featureModal ||
        !modalCard
    ) {
        return;
    }


    const elementosFocaveis =
        Array.from(
            featureModal.querySelectorAll(
                [
                    "button:not([disabled])",
                    "[href]",
                    "input:not([disabled])",
                    "select:not([disabled])",
                    "textarea:not([disabled])",
                    '[tabindex]:not([tabindex="-1"])'
                ].join(",")
            )
        ).filter(
            (elemento) =>
                elemento.offsetParent !== null
        );


    if (
        elementosFocaveis.length === 0
    ) {

        event.preventDefault();

        modalCard.focus();

        return;
    }


    const primeiro =
        elementosFocaveis[0];


    const ultimo =
        elementosFocaveis[
            elementosFocaveis.length - 1
        ];


    if (
        event.shiftKey &&
        document.activeElement ===
            primeiro
    ) {

        event.preventDefault();

        ultimo.focus();

        return;
    }


    if (
        !event.shiftKey &&
        document.activeElement ===
            ultimo
    ) {

        event.preventDefault();

        primeiro.focus();
    }
}


/* =========================================================
   ESQUECEU SUA SENHA
========================================================= */

if (esqueceuSenha) {

    esqueceuSenha.addEventListener(
        "click",
        () => {

            mostrarInformacao(
                "A recuperação de senha ainda não está habilitada. Entre em contato com o administrador do sistema."
            );


            if (mensagem) {

                mensagem.scrollIntoView({
                    behavior:
                        window.matchMedia(
                            "(prefers-reduced-motion: reduce)"
                        ).matches
                            ? "auto"
                            : "smooth",

                    block: "nearest"
                });
            }
        }
    );
}


/* =========================================================
   VLIBRAS
========================================================= */

window.addEventListener(
    "load",
    () => {

        if (
            !window.__movetechVLibras &&
            window.VLibras &&
            typeof window.VLibras.Widget
                === "function"
        ) {

            try {

                new window.VLibras.Widget(
                    "https://vlibras.gov.br/app"
                );

            } catch (erro) {

                console.warn(
                    "Não foi possível inicializar o VLibras.",
                    erro
                );
            }
        }
    }
);