/* =========================================================
   MOVETECH — ACESSIBILIDADE GLOBAL
   =========================================================
   Recursos:
   - Aumentar texto (A+)
   - Diminuir texto (A−)
   - Alto contraste
   - Restaurar configurações
   - Preferências salvas no navegador
   - Atalhos de teclado
   - Conteúdo carregado dinamicamente
   - Compatibilidade com Login e páginas internas
   - Compatibilidade com VLibras
   - Sem uso de zoom
   ========================================================= */

(() => {
    "use strict";

    /* =====================================================
       CONFIGURAÇÕES
       ===================================================== */

    const CHAVE_FONTE =
        "movetech-tamanho-fonte";

    const CHAVE_CONTRASTE =
        "movetech-alto-contraste";

    const FONTE_PADRAO = 100;

    const FONTE_MINIMA = 90;

    const FONTE_MAXIMA = 130;

    const PASSO = 10;


    /* =====================================================
       SELETORES DE TEXTO
       ===================================================== */

    const SELETOR_TEXTO = [

        /* =========================
           LOGIN
           ========================= */

        ".login-page h1",
        ".login-page h2",
        ".login-page h3",
        ".login-page h4",
        ".login-page h5",
        ".login-page h6",

        ".login-page p",
        ".login-page a",
        ".login-page label",
        ".login-page button",

        ".login-page input",
        ".login-page select",
        ".login-page textarea",

        ".login-page strong",
        ".login-page small",


        /* =========================
           SISTEMA INTERNO
           ========================= */

        ".app-layout h1",
        ".app-layout h2",
        ".app-layout h3",
        ".app-layout h4",
        ".app-layout h5",
        ".app-layout h6",

        ".app-layout p",
        ".app-layout a",
        ".app-layout button",
        ".app-layout label",

        ".app-layout input",
        ".app-layout select",
        ".app-layout textarea",

        ".app-layout th",
        ".app-layout td",

        ".app-layout strong",
        ".app-layout small",

        ".app-layout .lista-valor",
        ".app-layout .status-badge",
        ".app-layout .panel-badge",
        ".app-layout .welcome-badge",
        ".app-layout .hero-status",
        ".app-layout .report-status",


        /* =========================
           MODAIS
           ========================= */

        ".modal h1",
        ".modal h2",
        ".modal h3",
        ".modal h4",
        ".modal h5",
        ".modal h6",

        ".modal p",
        ".modal label",
        ".modal button",

        ".modal input",
        ".modal select",
        ".modal textarea",

        ".modal th",
        ".modal td",

        ".modal strong",
        ".modal small",


        /* =========================
           CARDS DE MODAL
           ========================= */

        ".modal-card h1",
        ".modal-card h2",
        ".modal-card h3",
        ".modal-card h4",

        ".modal-card p",
        ".modal-card label",
        ".modal-card button",

        ".modal-card input",
        ".modal-card select",
        ".modal-card textarea",

        ".modal-card th",
        ".modal-card td",

        ".modal-card strong",
        ".modal-card small"

    ].join(",");


    /* =====================================================
       ESTADO
       ===================================================== */

    let tamanhoFonte =
        obterTamanhoFonteSalvo();

    let contrasteAtivo =
        localStorage.getItem(
            CHAVE_CONTRASTE
        ) === "true";

    let observador = null;

    let temporizadorAnuncio = null;


    /* =====================================================
       OBTER TAMANHO SALVO
       ===================================================== */

    function obterTamanhoFonteSalvo() {

        const valor =
            Number(
                localStorage.getItem(
                    CHAVE_FONTE
                )
            );

        if (
            !Number.isFinite(valor) ||
            valor < FONTE_MINIMA ||
            valor > FONTE_MAXIMA
        ) {

            return FONTE_PADRAO;
        }

        return valor;
    }


    /* =====================================================
       ELEMENTOS DA BARRA
       ===================================================== */

    function obterElementos() {

        return {

            aumentar:
                document.getElementById(
                    "acessibilidade-aumentar"
                ),

            diminuir:
                document.getElementById(
                    "acessibilidade-diminuir"
                ),

            contraste:
                document.getElementById(
                    "acessibilidade-contraste"
                ),

            restaurar:
                document.getElementById(
                    "acessibilidade-restaurar"
                ),

            status:
                document.getElementById(
                    "acessibilidade-status"
                )
        };
    }


    /* =====================================================
       ELEMENTOS PROTEGIDOS
       ===================================================== */

    function elementoProtegido(elemento) {

        if (!(elemento instanceof HTMLElement)) {

            return true;
        }

        /*
            Não alteramos o tamanho da própria barra de
            acessibilidade.

            Também não modificamos os elementos internos
            do VLibras.
        */

        return Boolean(
            elemento.closest(
                [
                    ".acessibilidade-barra",

                    "[vw]",
                    "[vw-access-button]",
                    "[vw-plugin-wrapper]",

                    ".vw-plugin-wrapper",
                    ".vpw-container",
                    ".vpw-settings-btn"
                ].join(",")
            )
        );
    }


    /* =====================================================
       LEITOR DE TELA
       ===================================================== */

    function anunciar(texto) {

        const { status } =
            obterElementos();

        if (!status) {

            return;
        }

        window.clearTimeout(
            temporizadorAnuncio
        );

        status.textContent = "";

        temporizadorAnuncio =
            window.setTimeout(
                () => {

                    status.textContent =
                        texto;

                },
                50
            );
    }


    /* =====================================================
       REGISTRAR TAMANHO ORIGINAL
       ===================================================== */

    function registrarFonteOriginal(elemento) {

        if (!(elemento instanceof HTMLElement)) {

            return;
        }

        if (elementoProtegido(elemento)) {

            return;
        }

        /*
            O tamanho original é registrado apenas uma vez.

            Assim:

            100 -> 110 -> 120

            sempre é calculado sobre o tamanho original
            definido pelo CSS.
        */

        if (
            elemento.dataset
                .movetechFonteOriginal
        ) {

            return;
        }

        const estilo =
            window.getComputedStyle(
                elemento
            );

        const tamanho =
            Number.parseFloat(
                estilo.fontSize
            );

        if (
            Number.isFinite(tamanho) &&
            tamanho > 0
        ) {

            elemento.dataset
                .movetechFonteOriginal =
                    String(tamanho);
        }
    }


    /* =====================================================
       APLICAR TAMANHO EM UM ELEMENTO
       ===================================================== */

    function aplicarFonteNoElemento(elemento) {

        if (!(elemento instanceof HTMLElement)) {

            return;
        }

        if (elementoProtegido(elemento)) {

            return;
        }

        registrarFonteOriginal(
            elemento
        );

        const tamanhoOriginal =
            Number(
                elemento.dataset
                    .movetechFonteOriginal
            );

        if (
            !Number.isFinite(
                tamanhoOriginal
            )
        ) {

            return;
        }

        /*
            Em 100%, deixamos o CSS original controlar
            completamente o tamanho.
        */

        if (
            tamanhoFonte ===
            FONTE_PADRAO
        ) {

            elemento.style
                .removeProperty(
                    "font-size"
                );

            return;
        }

        const escala =
            tamanhoFonte / 100;

        const novoTamanho =
            tamanhoOriginal *
            escala;

        elemento.style.setProperty(
            "font-size",
            `${novoTamanho.toFixed(2)}px`,
            "important"
        );
    }


    /* =====================================================
       APLICAR TAMANHO DE TEXTO
       ===================================================== */

    function aplicarFonte() {

        const elementosTexto =
            document.querySelectorAll(
                SELETOR_TEXTO
            );

        elementosTexto.forEach(
            aplicarFonteNoElemento
        );

        localStorage.setItem(
            CHAVE_FONTE,
            String(tamanhoFonte)
        );

        document.documentElement
            .dataset.movetechFonte =
                String(tamanhoFonte);

        atualizarBotoes();
    }


    /* =====================================================
       LIMPAR ALTERAÇÕES DE FONTE
       ===================================================== */

    function limparFonteAplicada() {

        const elementos =
            document.querySelectorAll(
                "[data-movetech-fonte-original]"
            );

        elementos.forEach(
            (elemento) => {

                if (
                    !(
                        elemento instanceof
                        HTMLElement
                    )
                ) {

                    return;
                }

                elemento.style
                    .removeProperty(
                        "font-size"
                    );

                delete elemento.dataset
                    .movetechFonteOriginal;
            }
        );

        delete document
            .documentElement
            .dataset
            .movetechFonte;
    }


    /* =====================================================
       ESTADO DOS BOTÕES
       ===================================================== */

    function atualizarBotoes() {

        const {
            aumentar,
            diminuir,
            contraste
        } = obterElementos();


        /* AUMENTAR */

        if (aumentar) {

            const limite =
                tamanhoFonte >=
                FONTE_MAXIMA;

            aumentar.disabled =
                limite;

            aumentar.setAttribute(
                "aria-disabled",
                limite
                    ? "true"
                    : "false"
            );
        }


        /* DIMINUIR */

        if (diminuir) {

            const limite =
                tamanhoFonte <=
                FONTE_MINIMA;

            diminuir.disabled =
                limite;

            diminuir.setAttribute(
                "aria-disabled",
                limite
                    ? "true"
                    : "false"
            );
        }


        /* CONTRASTE */

        if (contraste) {

            contraste.setAttribute(
                "aria-pressed",
                contrasteAtivo
                    ? "true"
                    : "false"
            );

            contraste.setAttribute(
                "title",
                contrasteAtivo
                    ? "Desativar alto contraste"
                    : "Ativar alto contraste"
            );
        }
    }


    /* =====================================================
       AUMENTAR TEXTO
       ===================================================== */

    function aumentarFonte() {

        if (
            tamanhoFonte >=
            FONTE_MAXIMA
        ) {

            anunciar(
                "Tamanho máximo do texto atingido."
            );

            return;
        }

        tamanhoFonte +=
            PASSO;

        if (
            tamanhoFonte >
            FONTE_MAXIMA
        ) {

            tamanhoFonte =
                FONTE_MAXIMA;
        }

        aplicarFonte();

        anunciar(
            `Tamanho do texto ajustado para ${tamanhoFonte} por cento.`
        );
    }


    /* =====================================================
       DIMINUIR TEXTO
       ===================================================== */

    function diminuirFonte() {

        if (
            tamanhoFonte <=
            FONTE_MINIMA
        ) {

            anunciar(
                "Tamanho mínimo do texto atingido."
            );

            return;
        }

        tamanhoFonte -=
            PASSO;

        if (
            tamanhoFonte <
            FONTE_MINIMA
        ) {

            tamanhoFonte =
                FONTE_MINIMA;
        }

        aplicarFonte();

        anunciar(
            `Tamanho do texto ajustado para ${tamanhoFonte} por cento.`
        );
    }


    /* =====================================================
       ALTO CONTRASTE
       ===================================================== */

    function aplicarContraste() {

        if (!document.body) {

            return;
        }

        document.body
            .classList.toggle(
                "alto-contraste",
                contrasteAtivo
            );

        /*
            Também colocamos a classe no HTML.

            Isso aumenta a compatibilidade com os CSSs
            existentes das páginas do MoveTech.
        */

        document.documentElement
            .classList.toggle(
                "alto-contraste",
                contrasteAtivo
            );

        localStorage.setItem(
            CHAVE_CONTRASTE,
            String(contrasteAtivo)
        );

        atualizarBotoes();
    }


    function alternarContraste() {

        contrasteAtivo =
            !contrasteAtivo;

        aplicarContraste();

        anunciar(
            contrasteAtivo
                ? "Alto contraste ativado."
                : "Alto contraste desativado."
        );
    }


    /* =====================================================
       RESTAURAR CONFIGURAÇÕES
       ===================================================== */

    function restaurar() {

        tamanhoFonte =
            FONTE_PADRAO;

        contrasteAtivo =
            false;


        /* Remove preferências salvas */

        localStorage.removeItem(
            CHAVE_FONTE
        );

        localStorage.removeItem(
            CHAVE_CONTRASTE
        );


        /* Remove tamanhos inline */

        limparFonteAplicada();


        /* Remove contraste do BODY */

        if (document.body) {

            document.body
                .classList.remove(
                    "alto-contraste"
                );
        }


        /* Remove contraste do HTML */

        document.documentElement
            .classList.remove(
                "alto-contraste"
            );


        /*
            Limpeza de qualquer resíduo deixado
            por versões antigas.

            IMPORTANTE:
            este código NÃO aplica zoom.
        */

        document
            .querySelectorAll(
                [
                    ".login-page",
                    ".app-layout",
                    ".modal",
                    ".modal-overlay",
                    ".modal-card"
                ].join(",")
            )
            .forEach(
                (elemento) => {

                    if (
                        elemento instanceof
                        HTMLElement
                    ) {

                        elemento.style
                            .removeProperty(
                                "zoom"
                            );
                    }
                }
            );

        atualizarBotoes();

        anunciar(
            "Configurações de acessibilidade restauradas."
        );
    }


    /* =====================================================
       CONTEÚDO DINÂMICO
       ===================================================== */

    function configurarObservador() {

        if (
            !(
                "MutationObserver"
                in window
            )
        ) {

            return;
        }

        observador =
            new MutationObserver(
                (mutacoes) => {

                    /*
                        Em 100%, não precisamos modificar
                        elementos adicionados posteriormente.
                    */

                    if (
                        tamanhoFonte ===
                        FONTE_PADRAO
                    ) {

                        return;
                    }

                    mutacoes.forEach(
                        (mutacao) => {

                            mutacao.addedNodes
                                .forEach(
                                    (no) => {

                                        if (
                                            !(
                                                no instanceof
                                                HTMLElement
                                            )
                                        ) {

                                            return;
                                        }

                                        if (
                                            elementoProtegido(
                                                no
                                            )
                                        ) {

                                            return;
                                        }


                                        /*
                                            Testa o próprio elemento.
                                        */

                                        if (
                                            no.matches?.(
                                                SELETOR_TEXTO
                                            )
                                        ) {

                                            aplicarFonteNoElemento(
                                                no
                                            );
                                        }


                                        /*
                                            Testa os filhos.
                                        */

                                        no.querySelectorAll?.(
                                            SELETOR_TEXTO
                                        )
                                            .forEach(
                                                aplicarFonteNoElemento
                                            );
                                    }
                                );
                        }
                    );
                }
            );

        if (document.body) {

            observador.observe(
                document.body,
                {
                    childList: true,
                    subtree: true
                }
            );
        }
    }


    /* =====================================================
       ATALHOS DE TECLADO
       ===================================================== */

    function configurarTeclado() {

        document.addEventListener(
            "keydown",
            (event) => {


                /* ALT + + ou ALT + = */

                if (
                    event.altKey &&
                    (
                        event.key === "+" ||
                        event.key === "="
                    )
                ) {

                    event.preventDefault();

                    aumentarFonte();

                    return;
                }


                /* ALT + - */

                if (
                    event.altKey &&
                    event.key === "-"
                ) {

                    event.preventDefault();

                    diminuirFonte();

                    return;
                }


                /* ALT + C */

                if (
                    event.altKey &&
                    event.key.toLowerCase() === "c"
                ) {

                    event.preventDefault();

                    alternarContraste();

                    return;
                }


                /* ALT + R */

                if (
                    event.altKey &&
                    event.key.toLowerCase() === "r"
                ) {

                    event.preventDefault();

                    restaurar();
                }
            }
        );
    }


    /* =====================================================
       REMOVER RESÍDUOS DE VERSÕES ANTIGAS
       ===================================================== */

    function removerZoomAntigo() {

        /*
            Esta versão NÃO utiliza zoom.

            Apenas removemos valores deixados
            por implementações antigas.
        */

        const elementos =
            document.querySelectorAll(
                [
                    ".login-page",
                    ".app-layout",
                    ".modal",
                    ".modal-overlay",
                    ".modal-card"
                ].join(",")
            );

        elementos.forEach(
            (elemento) => {

                if (
                    elemento instanceof
                    HTMLElement
                ) {

                    elemento.style
                        .removeProperty(
                            "zoom"
                        );
                }
            }
        );


        /*
            Remove variáveis antigas.
        */

        document.documentElement
            .style.removeProperty(
                "--movetech-escala-texto"
            );

        document.documentElement
            .style.removeProperty(
                "font-size"
            );

        if (document.body) {

            document.body.style
                .removeProperty(
                    "--movetech-escala-texto"
                );
        }
    }


    /* =====================================================
       CONFIGURAR EVENTOS
       ===================================================== */

    function configurarEventos() {

        const {
            aumentar,
            diminuir,
            contraste,
            restaurar: botaoRestaurar
        } = obterElementos();


        aumentar?.addEventListener(
            "click",
            aumentarFonte
        );


        diminuir?.addEventListener(
            "click",
            diminuirFonte
        );


        contraste?.addEventListener(
            "click",
            alternarContraste
        );


        botaoRestaurar?.addEventListener(
            "click",
            restaurar
        );
    }


    /* =====================================================
       INICIALIZAÇÃO
       ===================================================== */

    function iniciar() {

        /*
            Limpa resíduos antigos antes
            de inicializar a nova versão.
        */

        removerZoomAntigo();


        /*
            Configura os botões.
        */

        configurarEventos();


        /*
            Configura atalhos.
        */

        configurarTeclado();


        /*
            Aplica tamanho salvo.
        */

        aplicarFonte();


        /*
            Aplica contraste salvo.
        */

        aplicarContraste();


        /*
            Observa elementos criados
            dinamicamente.
        */

        configurarObservador();


        /*
            Atualiza estado visual.
        */

        atualizarBotoes();
    }


    /* =====================================================
       EXECUÇÃO
       ===================================================== */

    if (
        document.readyState ===
        "loading"
    ) {

        document.addEventListener(
            "DOMContentLoaded",
            iniciar,
            {
                once: true
            }
        );

    } else {

        iniciar();
    }

})();

/* =========================================================
   VLIBRAS (todas as páginas)
   O widget do governo precisa da marcação <div vw> na página
   e de ser iniciado depois que o script dele carrega. Antes só
   o login tentava iniciar e nenhuma página tinha a marcação,
   então o botão de Libras não aparecia.
   ========================================================= */

(() => {
    "use strict";

    function montarMarcacaoVLibras() {
        if (document.querySelector("[vw]")) {
            return;
        }

        const raiz = document.createElement("div");
        raiz.setAttribute("vw", "");
        raiz.className = "enabled";

        const botao = document.createElement("div");
        botao.setAttribute("vw-access-button", "");
        botao.className = "active";

        const janela = document.createElement("div");
        janela.setAttribute("vw-plugin-wrapper", "");

        const topo = document.createElement("div");
        topo.className = "vw-plugin-top-wrapper";

        janela.appendChild(topo);
        raiz.appendChild(botao);
        raiz.appendChild(janela);
        document.body.appendChild(raiz);
    }

    window.addEventListener("load", () => {
        montarMarcacaoVLibras();

        if (
            window.__movetechVLibras ||
            !window.VLibras ||
            typeof window.VLibras.Widget !== "function"
        ) {
            return;
        }

        try {
            window.__movetechVLibras = true;
            new window.VLibras.Widget("https://vlibras.gov.br/app");
        } catch (erro) {
            console.warn("Não foi possível inicializar o VLibras.", erro);
        }
    });
})();
