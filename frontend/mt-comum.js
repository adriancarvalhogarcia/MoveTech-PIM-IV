/* ==========================================================
   MOVETECH — FUNÇÕES COMPARTILHADAS (PIM IV)
   ----------------------------------------------------------
   - Sessão (token JWT e usuário logado)
   - Requisições à API com tratamento de 401/403
   - Formatação de moeda e data
   - Menu lateral: adiciona Notas de entrada, Financeiro e
     Usuários (só para administradores)
   - Modais acessíveis (abrir/fechar, Esc, foco)

   Tudo fica dentro de window.MT para não conflitar com as
   variáveis já declaradas nos scripts de cada tela.
   ========================================================== */

(function () {

    const API_URL = "http://localhost:5071/api";

    const token = sessionStorage.getItem("smartmoveis_token");

    let usuario = null;

    try {
        usuario = JSON.parse(sessionStorage.getItem("smartmoveis_usuario") || "null");
    } catch {
        usuario = null;
    }

    const perfil = usuario?.perfil || usuario?.Perfil || "";
    const administrador = perfil.toLowerCase().startsWith("admin");

    const NOMES_PERFIL = {
        Administrador: "Administrador",
        Funcionario: "Funcionário",
        Vendedor: "Funcionário"
    };

    const NOMES_FORMA = {
        Dinheiro: "Dinheiro",
        Pix: "Pix",
        CartaoDebito: "Cartão de débito",
        CartaoCredito: "Cartão de crédito",
        Boleto: "Boleto",
        Crediario: "Crediário",
        Transferencia: "Transferência",
        NaoInformada: "Não informada"
    };

    const ICONES = {
        notas: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8Z"/><path d="M14 3v5h5"/><path d="M12 11v6"/><path d="m9 14 3 3 3-3"/>',
        financeiro: '<rect x="2" y="6" width="20" height="13" rx="2"/><path d="M2 10h20"/><path d="M6 15h4"/>',
        usuarios: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/><path d="M19 4l2 2-2 2"/>'
    };

    // ------------------------------------------------------
    // SESSÃO
    // ------------------------------------------------------

    function sair() {
        sessionStorage.removeItem("smartmoveis_token");
        sessionStorage.removeItem("smartmoveis_usuario");
        window.location.href = "index.html";
    }

    /** Página exclusiva do administrador: funcionário volta ao dashboard. */
    function exigirAdministrador() {
        if (!token) {
            sair();
            return false;
        }

        if (!administrador) {
            window.location.href = "dashboard.html";
            return false;
        }

        return true;
    }

    // ------------------------------------------------------
    // API
    // ------------------------------------------------------

    /**
     * Chama a API e devolve o JSON. Lança Error com a mensagem
     * enviada pela API ("mensagem") em caso de falha.
     */
    async function api(caminho, opcoes = {}) {
        const headers = {
            ...(opcoes.headers || {}),
            Authorization: `Bearer ${token}`
        };

        let body = opcoes.body;

        if (body !== undefined && typeof body !== "string") {
            body = JSON.stringify(body);
        }

        if (body !== undefined) {
            headers["Content-Type"] = "application/json";
        }

        let resposta;

        try {
            resposta = await fetch(`${API_URL}${caminho}`, { ...opcoes, headers, body });
        } catch {
            throw new Error("Não foi possível conectar à API. Verifique se ela está em execução.");
        }

        if (resposta.status === 401) {
            sair();
            throw new Error("Sua sessão expirou. Faça login novamente.");
        }

        let dados = null;

        try {
            dados = await resposta.json();
        } catch {
            dados = null;
        }

        if (!resposta.ok) {
            const mensagem =
                dados?.mensagem ||
                (dados?.errors && Object.values(dados.errors).flat()[0]) ||
                (resposta.status === 403
                    ? "Seu perfil não tem permissão para esta operação."
                    : "Não foi possível concluir a operação.");

            const erro = new Error(mensagem);
            erro.status = resposta.status;
            erro.dados = dados;
            throw erro;
        }

        return dados;
    }

    // ------------------------------------------------------
    // FORMATAÇÃO
    // ------------------------------------------------------

    const formatoMoeda = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });

    function moeda(valor) {
        return formatoMoeda.format(Number(valor || 0));
    }

    /** Data sem fuso (yyyy-mm-dd ou ISO) para dd/mm/aaaa. */
    function data(valor) {
        if (!valor) return "-";
        const texto = String(valor);
        const [ano, mes, dia] = texto.slice(0, 10).split("-");
        return dia && mes && ano ? `${dia}/${mes}/${ano}` : texto;
    }

    function dataHora(valor) {
        if (!valor) return "-";
        const texto = String(valor);
        const dataUtc = new Date(/[zZ]|[+-]\d\d:\d\d$/.test(texto) ? texto : `${texto}Z`);
        return Number.isNaN(dataUtc.getTime())
            ? data(texto)
            : dataUtc.toLocaleString("pt-BR", { dateStyle: "short", timeStyle: "short" });
    }

    function hojeIso() {
        const agora = new Date();
        const local = new Date(agora.getTime() - agora.getTimezoneOffset() * 60000);
        return local.toISOString().slice(0, 10);
    }

    function somarDias(iso, dias) {
        const [a, m, d] = iso.split("-").map(Number);
        const dt = new Date(a, m - 1, d + dias);
        return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
    }

    function escapar(valor) {
        return String(valor ?? "")
            .replaceAll("&", "&amp;")
            .replaceAll("<", "&lt;")
            .replaceAll(">", "&gt;")
            .replaceAll('"', "&quot;")
            .replaceAll("'", "&#039;");
    }

    function nomeForma(forma) {
        return NOMES_FORMA[forma] || forma || "-";
    }

    function nomePerfil(valor) {
        return NOMES_PERFIL[valor] || valor || "-";
    }

    // ------------------------------------------------------
    // MENSAGENS (usa .feedback-message do movetech.css)
    // ------------------------------------------------------

    function mensagem(elemento, texto, tipo = "erro") {
        if (!elemento) return;
        elemento.textContent = texto || "";
        elemento.dataset.tipo = tipo;
        elemento.hidden = !texto;

        if (texto && tipo === "sucesso") {
            clearTimeout(elemento._timer);
            elemento._timer = setTimeout(() => mensagem(elemento, ""), 6000);
        }
    }

    // ------------------------------------------------------
    // MODAIS
    // ------------------------------------------------------

    let ultimoFoco = null;

    function abrirModal(modal) {
        if (!modal) return;
        ultimoFoco = document.activeElement;
        modal.hidden = false;
        modal.setAttribute("aria-hidden", "false");
        const primeiro = modal.querySelector("input:not([type=hidden]):not([disabled]), select, textarea, button");
        setTimeout(() => primeiro?.focus(), 30);
    }

    function fecharModal(modal) {
        if (!modal) return;
        modal.hidden = true;
        modal.setAttribute("aria-hidden", "true");
        ultimoFoco?.focus?.();
    }

    /** Liga botões [data-fechar] e clique fora em todos os modais .mt-modal. */
    function prepararModais() {
        document.querySelectorAll(".mt-modal").forEach(modal => {
            modal.addEventListener("click", evento => {
                if (evento.target === modal || evento.target.closest("[data-fechar]")) {
                    fecharModal(modal);
                }
            });
        });

        document.addEventListener("keydown", evento => {
            if (evento.key !== "Escape") return;
            const aberto = [...document.querySelectorAll(".mt-modal")].reverse().find(m => !m.hidden);
            if (aberto) fecharModal(aberto);
        });
    }

    // ------------------------------------------------------
    // MENU LATERAL
    // ------------------------------------------------------

    function link(href, texto, icone) {
        const a = document.createElement("a");
        a.href = href;
        a.innerHTML =
            `<span aria-hidden="true"><svg class="mt-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${icone}</svg></span>` +
            escapar(texto);
        return a;
    }

    function montarMenu() {
        const menu = document.querySelector(".sidebar .menu");
        if (!menu || menu.dataset.mtPronto) return;
        menu.dataset.mtPronto = "1";

        if (administrador) {
            const relatorios = menu.querySelector('a[href="relatorios.html"]');
            const extras = [
                link("notas.html", "Notas de entrada", ICONES.notas),
                link("financeiro.html", "Financeiro", ICONES.financeiro),
                link("usuarios.html", "Usuários", ICONES.usuarios)
            ];
            extras.forEach(a => menu.insertBefore(a, relatorios || null));
        }

        const pagina = location.pathname.split("/").pop() || "dashboard.html";

        menu.querySelectorAll("a").forEach(a => {
            const ativo = a.getAttribute("href") === pagina;
            a.classList.toggle("active", ativo);
            if (ativo) a.setAttribute("aria-current", "page");
            else a.removeAttribute("aria-current");
        });

        // Nome e perfil no rodapé do menu
        const nome = document.getElementById("usuario-nome");
        const perfilEl = document.getElementById("usuario-perfil");
        if (nome && usuario?.nome) nome.textContent = usuario.nome;
        if (perfilEl && perfil) perfilEl.textContent = nomePerfil(perfil);

        // Funcionário só consulta produtos: esconde cadastro, edição e desativação.
        if (!administrador && pagina === "produtos.html") {
            const estilo = document.createElement("style");
            estilo.textContent = "#botao-novo-produto, .botao-acao { display: none !important; }";
            document.head.appendChild(estilo);
        }

        const botaoSair = document.getElementById("botao-sair");
        if (botaoSair && !botaoSair.dataset.mtSair) {
            botaoSair.dataset.mtSair = "1";
            botaoSair.addEventListener("click", sair);
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", montarMenu);
    } else {
        montarMenu();
    }

    window.MT = {
        API_URL,
        token,
        usuario,
        perfil,
        administrador,
        api,
        sair,
        exigirAdministrador,
        moeda,
        data,
        dataHora,
        hojeIso,
        somarDias,
        escapar,
        nomeForma,
        nomePerfil,
        mensagem,
        abrirModal,
        fecharModal,
        prepararModais,
        montarMenu,
        NOMES_FORMA
    };
})();
