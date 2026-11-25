/* ==========================================================
   MOVETECH — FINANCEIRO (somente administrador)
   Contas a pagar e a receber: resumo, filtros, baixa com forma
   de pagamento, estorno, lançamento avulso, cancelamento e
   histórico de cada conta.
   ========================================================== */

if (MT.exigirAdministrador()) {

    const tabela = document.getElementById("tabela-contas");
    const mensagem = document.getElementById("mensagem-financeiro");
    const totalFiltrado = document.getElementById("total-filtrado");
    const abas = document.querySelectorAll(".mod-abas [data-tipo]");
    const filtroStatus = document.getElementById("filtro-status");
    const filtroDe = document.getElementById("filtro-de");
    const filtroAte = document.getElementById("filtro-ate");
    const filtroBusca = document.getElementById("filtro-busca");

    const modalBaixar = document.getElementById("modal-baixar");
    const formBaixar = document.getElementById("form-baixar");
    const baixarId = document.getElementById("baixar-id");
    const baixarResumo = document.getElementById("baixar-resumo");
    const baixarForma = document.getElementById("baixar-forma");
    const baixarData = document.getElementById("baixar-data");
    const baixarValor = document.getElementById("baixar-valor");
    const baixarObs = document.getElementById("baixar-obs");
    const mensagemBaixar = document.getElementById("mensagem-baixar");
    const tituloBaixar = document.getElementById("titulo-baixar");

    const modalMotivo = document.getElementById("modal-motivo");
    const formMotivo = document.getElementById("form-motivo");
    const motivoId = document.getElementById("motivo-id");
    const motivoAcao = document.getElementById("motivo-acao");
    const motivoTexto = document.getElementById("motivo-texto");
    const motivoCampo = document.getElementById("motivo-campo");
    const mensagemMotivo = document.getElementById("mensagem-motivo");
    const tituloMotivo = document.getElementById("titulo-motivo");
    const kickerMotivo = document.getElementById("kicker-motivo");
    const botaoMotivo = document.getElementById("botao-motivo");

    const modalConta = document.getElementById("modal-conta");
    const formConta = document.getElementById("form-conta");
    const contaTipo = document.getElementById("conta-tipo");
    const contaVinculo = document.getElementById("conta-vinculo");
    const contaDescricao = document.getElementById("conta-descricao");
    const contaValor = document.getElementById("conta-valor");
    const contaParcelas = document.getElementById("conta-parcelas");
    const contaVencimento = document.getElementById("conta-vencimento");
    const contaObs = document.getElementById("conta-obs");
    const mensagemConta = document.getElementById("mensagem-conta");

    const modalHistorico = document.getElementById("modal-historico");
    const conteudoHistorico = document.getElementById("conteudo-historico");

    let tipoAtual = "";
    let contas = [];
    let clientes = [];
    let fornecedores = [];
    let temporizadorBusca = null;

    const ORIGENS = {
        Venda: "Venda",
        NotaEntrada: "Nota de entrada",
        Devolucao: "Devolução",
        Manual: "Lançamento avulso"
    };

    // ------------------------------------------------------
    // RESUMO
    // ------------------------------------------------------

    async function carregarResumo() {
        try {
            const r = await MT.api("/financeiro/resumo");
            document.getElementById("r-receber").textContent = MT.moeda(r.aReceber);
            document.getElementById("r-pagar").textContent = MT.moeda(r.aPagar);
            document.getElementById("r-recebido").textContent = MT.moeda(r.recebidoMes);
            document.getElementById("r-pago").textContent = MT.moeda(r.pagoMes);
            document.getElementById("r-saldo").textContent = MT.moeda(r.saldoPrevisto);
            document.getElementById("r-receber-vencido").textContent =
                r.receberVencido > 0 ? `${MT.moeda(r.receberVencido)} vencido` : "nada vencido";
            document.getElementById("r-pagar-vencido").textContent =
                r.pagarVencido > 0 ? `${MT.moeda(r.pagarVencido)} vencido` : "nada vencido";
            document.getElementById("card-saldo").className =
                `mod-card ${r.saldoPrevisto >= 0 ? "positivo" : "negativo"}`;
        } catch (erro) {
            MT.mensagem(mensagem, erro.message);
        }
    }

    // ------------------------------------------------------
    // LISTA
    // ------------------------------------------------------

    async function carregarContas() {
        const parametros = new URLSearchParams();
        if (tipoAtual) parametros.set("tipo", tipoAtual);
        if (filtroStatus.value) parametros.set("status", filtroStatus.value);
        if (filtroDe.value) parametros.set("de", filtroDe.value);
        if (filtroAte.value) parametros.set("ate", filtroAte.value);
        if (filtroBusca.value.trim()) parametros.set("busca", filtroBusca.value.trim());

        if (filtroDe.value && filtroAte.value && filtroDe.value > filtroAte.value) {
            MT.mensagem(mensagem, "A data inicial do filtro é maior que a final.");
            return;
        }

        tabela.innerHTML = '<tr><td colspan="7" class="mod-vazio">Carregando contas...</td></tr>';

        try {
            contas = await MT.api(`/financeiro?${parametros}`);
            renderizar();
        } catch (erro) {
            tabela.innerHTML = `<tr><td colspan="7" class="mod-vazio">${MT.escapar(erro.message)}</td></tr>`;
        }
    }

    function badge(conta) {
        if (conta.status === "Paga") {
            return `<span class="badge badge-ok">${conta.tipo === "Receber" ? "Recebida" : "Paga"}</span>
                    <br><span class="texto-fraco">${MT.data(conta.dataPagamento)} · ${MT.escapar(MT.nomeForma(conta.formaPagamento))}</span>`;
        }
        if (conta.status === "Cancelada") return '<span class="badge badge-cancelada">Cancelada</span>';
        if (conta.vencida) return '<span class="badge badge-vencida">Vencida</span>';
        return '<span class="badge badge-aberta">Em aberto</span>';
    }

    function acoes(conta) {
        const botoes = [];
        const nome = MT.escapar(conta.descricao);

        if (conta.status === "Aberta") {
            botoes.push(`<button type="button" class="mod-botao" data-acao="baixar" data-id="${conta.id}"
                aria-label="Baixar ${nome}">${conta.tipo === "Receber" ? "Receber" : "Pagar"}</button>`);
        }
        if (conta.status === "Paga") {
            botoes.push(`<button type="button" class="mod-botao perigo" data-acao="estornar" data-id="${conta.id}"
                aria-label="Estornar baixa de ${nome}">Estornar</button>`);
        }
        if (conta.status === "Aberta" && conta.origem === "Manual") {
            botoes.push(`<button type="button" class="mod-botao perigo" data-acao="cancelar" data-id="${conta.id}"
                aria-label="Cancelar ${nome}">Cancelar</button>`);
        }
        botoes.push(`<button type="button" class="mod-botao" data-acao="historico" data-id="${conta.id}"
            aria-label="Histórico de ${nome}">Histórico</button>`);

        return `<div class="mod-acoes">${botoes.join("")}</div>`;
    }

    function renderizar() {
        if (contas.length === 0) {
            tabela.innerHTML = '<tr><td colspan="7" class="mod-vazio">Nenhuma conta encontrada com estes filtros.</td></tr>';
            totalFiltrado.textContent = "";
            return;
        }

        tabela.innerHTML = contas.map(c => `
            <tr>
                <td><span class="${c.tipo === "Receber" ? "tipo-receber" : "tipo-pagar"}">
                    ${c.tipo === "Receber" ? "↓ Receber" : "↑ Pagar"}</span></td>
                <td>
                    <strong>${MT.escapar(c.descricao)}</strong><br>
                    <span class="texto-fraco">${ORIGENS[c.origem] || c.origem}${c.observacao ? " · " + MT.escapar(c.observacao) : ""}</span>
                </td>
                <td>${MT.escapar(c.cliente || c.fornecedor || "-")}</td>
                <td>${MT.data(c.vencimento)}</td>
                <td class="valor">${MT.moeda(c.valor)}${
                    c.status === "Paga" && Number(c.valorPago) !== Number(c.valor)
                        ? `<br><span class="texto-fraco">pago ${MT.moeda(c.valorPago)}</span>` : ""}</td>
                <td>${badge(c)}</td>
                <td>${acoes(c)}</td>
            </tr>`).join("");

        const somaAberta = contas.filter(c => c.status === "Aberta")
            .reduce((s, c) => s + (c.tipo === "Receber" ? 1 : -1) * Number(c.valor), 0);

        totalFiltrado.textContent =
            `${contas.length} conta(s) listada(s)${contas.length >= 500 ? " (limite de 500 — refine o filtro)" : ""}. ` +
            `Saldo em aberto da lista: ${MT.moeda(somaAberta)}.`;
    }

    async function recarregar() {
        await Promise.all([carregarResumo(), carregarContas()]);
    }

    // ------------------------------------------------------
    // BAIXA
    // ------------------------------------------------------

    function abrirBaixa(conta) {
        formBaixar.reset();
        MT.mensagem(mensagemBaixar, "");
        baixarId.value = conta.id;
        tituloBaixar.textContent = conta.tipo === "Receber" ? "Registrar recebimento" : "Registrar pagamento";
        baixarData.value = MT.hojeIso();
        baixarData.max = MT.hojeIso();
        baixarValor.value = Number(conta.valor).toFixed(2);

        baixarResumo.innerHTML = `
            <div class="mod-resumo-linha"><span>${MT.escapar(conta.descricao)}</span><strong>${MT.moeda(conta.valor)}</strong></div>
            <div class="mod-resumo-linha"><span>Vencimento</span><span>${MT.data(conta.vencimento)}${conta.vencida ? ' <span class="badge badge-vencida">Vencida</span>' : ""}</span></div>
            <div class="mod-resumo-linha"><span>${conta.tipo === "Receber" ? "Cliente" : "Fornecedor"}</span><span>${MT.escapar(conta.cliente || conta.fornecedor || "-")}</span></div>`;

        MT.abrirModal(modalBaixar);
    }

    async function confirmarBaixa(evento) {
        evento.preventDefault();

        const valor = Number(baixarValor.value);

        if (!baixarForma.value) return MT.mensagem(mensagemBaixar, "Informe como foi pago.");
        if (!baixarData.value) return MT.mensagem(mensagemBaixar, "Informe a data do pagamento.");
        if (baixarData.value > MT.hojeIso()) return MT.mensagem(mensagemBaixar, "A data não pode ser futura.");
        if (!(valor > 0)) return MT.mensagem(mensagemBaixar, "Informe o valor pago.");

        try {
            const resposta = await MT.api(`/financeiro/${baixarId.value}/baixar`, {
                method: "POST",
                body: {
                    formaPagamento: baixarForma.value,
                    dataPagamento: baixarData.value,
                    valorPago: valor,
                    observacao: baixarObs.value.trim() || null
                }
            });
            MT.fecharModal(modalBaixar);
            MT.mensagem(mensagem, resposta.mensagem, "sucesso");
            await recarregar();
        } catch (erro) {
            MT.mensagem(mensagemBaixar, erro.message);
        }
    }

    // ------------------------------------------------------
    // ESTORNO / CANCELAMENTO
    // ------------------------------------------------------

    function abrirMotivo(conta, acao) {
        formMotivo.reset();
        MT.mensagem(mensagemMotivo, "");
        motivoId.value = conta.id;
        motivoAcao.value = acao;

        if (acao === "estornar") {
            kickerMotivo.textContent = "ESTORNO";
            tituloMotivo.textContent = "Estornar baixa";
            motivoTexto.textContent =
                `A conta "${conta.descricao}" volta a ficar em aberto. ` +
                `Baixa atual: ${MT.nomeForma(conta.formaPagamento)} de ${MT.moeda(conta.valorPago)} em ${MT.data(conta.dataPagamento)}.`;
            botaoMotivo.textContent = "Estornar";
        } else {
            kickerMotivo.textContent = "CANCELAMENTO";
            tituloMotivo.textContent = "Cancelar conta";
            motivoTexto.textContent = `A conta "${conta.descricao}" (${MT.moeda(conta.valor)}) será cancelada.`;
            botaoMotivo.textContent = "Cancelar conta";
        }

        MT.abrirModal(modalMotivo);
    }

    async function confirmarMotivo(evento) {
        evento.preventDefault();

        const motivo = motivoCampo.value.trim();

        if (motivo.length < 3) {
            MT.mensagem(mensagemMotivo, "Descreva o motivo (mínimo de 3 caracteres).");
            return;
        }

        try {
            const resposta = await MT.api(`/financeiro/${motivoId.value}/${motivoAcao.value}`, {
                method: "POST",
                body: { motivo }
            });
            MT.fecharModal(modalMotivo);
            MT.mensagem(mensagem, resposta.mensagem, "sucesso");
            await recarregar();
        } catch (erro) {
            MT.mensagem(mensagemMotivo, erro.message);
        }
    }

    // ------------------------------------------------------
    // LANÇAMENTO AVULSO
    // ------------------------------------------------------

    async function abrirNovaConta() {
        formConta.reset();
        MT.mensagem(mensagemConta, "");
        contaVencimento.value = MT.hojeIso();
        MT.abrirModal(modalConta);

        if (clientes.length === 0 && fornecedores.length === 0) {
            try {
                [clientes, fornecedores] = await Promise.all([MT.api("/clientes"), MT.api("/fornecedores")]);
            } catch {
                clientes = [];
                fornecedores = [];
            }
        }

        preencherVinculos();
    }

    function preencherVinculos() {
        const receber = contaTipo.value === "Receber";
        const lista = receber
            ? clientes.filter(c => c.ativo).map(c => ({ id: c.id, nome: c.nome }))
            : fornecedores.map(f => ({ id: f.id, nome: f.razaoSocial }));

        contaVinculo.innerHTML =
            `<option value="">Nenhum</option>` +
            lista.map(i => `<option value="${i.id}">${MT.escapar(i.nome)}</option>`).join("");

        contaVinculo.previousElementSibling.textContent = receber ? "Cliente (opcional)" : "Fornecedor (opcional)";
    }

    async function salvarConta(evento) {
        evento.preventDefault();

        const descricao = contaDescricao.value.trim();
        const valor = Number(contaValor.value);
        const parcelas = Number(contaParcelas.value);

        if (descricao.length < 3) return MT.mensagem(mensagemConta, "Informe a descrição.");
        if (!(valor > 0)) return MT.mensagem(mensagemConta, "Informe um valor maior que zero.");
        if (!Number.isInteger(parcelas) || parcelas < 1 || parcelas > 24)
            return MT.mensagem(mensagemConta, "Parcelas devem estar entre 1 e 24.");
        if (!contaVencimento.value) return MT.mensagem(mensagemConta, "Informe o vencimento.");
        if (valor / parcelas < 0.01) return MT.mensagem(mensagemConta, "Valor muito baixo para tantas parcelas.");

        const corpo = {
            tipo: contaTipo.value,
            descricao,
            valor,
            parcelas,
            vencimento: contaVencimento.value,
            observacao: contaObs.value.trim() || null
        };

        if (contaVinculo.value) {
            corpo[contaTipo.value === "Receber" ? "clienteId" : "fornecedorId"] = Number(contaVinculo.value);
        }

        try {
            const resposta = await MT.api("/financeiro", { method: "POST", body: corpo });
            MT.fecharModal(modalConta);
            MT.mensagem(mensagem, resposta.mensagem, "sucesso");
            await recarregar();
        } catch (erro) {
            MT.mensagem(mensagemConta, erro.message);
        }
    }

    // ------------------------------------------------------
    // HISTÓRICO
    // ------------------------------------------------------

    async function abrirHistorico(id) {
        conteudoHistorico.innerHTML = '<p class="mod-vazio">Carregando...</p>';
        MT.abrirModal(modalHistorico);

        try {
            const conta = await MT.api(`/financeiro/${id}`);
            conteudoHistorico.innerHTML = `
                <div class="mod-resumo-linha"><span>${MT.escapar(conta.descricao)}</span><strong>${MT.moeda(conta.valor)}</strong></div>
                <div class="mod-resumo-linha"><span>Origem</span><span>${ORIGENS[conta.origem] || conta.origem}${
                    conta.vendaId ? ` · venda #${conta.vendaId}` : ""}${conta.notaEntradaId ? ` · nota #${conta.notaEntradaId}` : ""}</span></div>
                <h3>Movimentações</h3>
                <ul class="mod-historico">
                    ${conta.historico.map(h => `
                        <li>
                            <strong>${MT.escapar(h.acao)}</strong> · ${MT.dataHora(h.criadoEm)}
                            ${h.usuarioNome ? `· ${MT.escapar(h.usuarioNome)}` : ""}
                            ${h.detalhe ? `<br><span class="texto-fraco">${MT.escapar(h.detalhe)}</span>` : ""}
                        </li>`).join("")}
                </ul>`;
        } catch (erro) {
            conteudoHistorico.innerHTML = `<p class="mod-vazio">${MT.escapar(erro.message)}</p>`;
        }
    }

    // ------------------------------------------------------
    // EVENTOS
    // ------------------------------------------------------

    abas.forEach(aba => aba.addEventListener("click", () => {
        abas.forEach(a => a.setAttribute("aria-selected", String(a === aba)));
        tipoAtual = aba.dataset.tipo;
        carregarContas();
    }));

    [filtroStatus, filtroDe, filtroAte].forEach(campo => campo.addEventListener("change", carregarContas));

    filtroBusca.addEventListener("input", () => {
        clearTimeout(temporizadorBusca);
        temporizadorBusca = setTimeout(carregarContas, 350);
    });

    tabela.addEventListener("click", evento => {
        const botao = evento.target.closest("[data-acao]");
        if (!botao) return;

        const conta = contas.find(c => c.id === Number(botao.dataset.id));
        if (!conta) return;

        if (botao.dataset.acao === "baixar") abrirBaixa(conta);
        if (botao.dataset.acao === "estornar") abrirMotivo(conta, "estornar");
        if (botao.dataset.acao === "cancelar") abrirMotivo(conta, "cancelar");
        if (botao.dataset.acao === "historico") abrirHistorico(conta.id);
    });

    document.getElementById("botao-nova-conta").addEventListener("click", abrirNovaConta);
    contaTipo.addEventListener("change", preencherVinculos);
    formBaixar.addEventListener("submit", confirmarBaixa);
    formMotivo.addEventListener("submit", confirmarMotivo);
    formConta.addEventListener("submit", salvarConta);

    MT.prepararModais();
    recarregar();
}
