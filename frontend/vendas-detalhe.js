/* ==========================================================
   MOVETECH — VENDAS: PAGAMENTO, DETALHES E DEVOLUÇÃO (PIM IV)
   - Parcelas conforme a forma de pagamento da nova venda
   - Detalhes da venda com itens, devoluções e contas a receber
   - Devolução total ou parcial por item
   ========================================================== */

(function () {

    const A_VISTA = ["Dinheiro", "Pix", "CartaoDebito"];

    // ------------------------------------------------------
    // PARCELAS DA NOVA VENDA
    // ------------------------------------------------------

    const forma = document.getElementById("formaPagamentoVenda");
    const parcelas = document.getElementById("parcelasVenda");
    const ajuda = document.getElementById("ajudaPagamento");
    const total = document.getElementById("totalVendaModal");
    const formVendaEl = document.getElementById("formVenda");

    function totalAtual() {
        const texto = (total?.textContent || "").replace(/[^\d,-]/g, "").replace(",", ".");
        return Number(texto) || 0;
    }

    function atualizarParcelas() {
        if (!forma || !parcelas) return;

        const valor = totalAtual();
        const escolhida = Number(parcelas.value) || 1;
        const aVista = !forma.value || A_VISTA.includes(forma.value);

        if (aVista) {
            parcelas.innerHTML = '<option value="1">1x (à vista)</option>';
            parcelas.disabled = true;
            ajuda.textContent = forma.value
                ? "Recebido na hora: a conta a receber já entra como recebida."
                : "Dinheiro, Pix e débito são recebidos na hora.";
            return;
        }

        parcelas.disabled = false;
        parcelas.innerHTML = Array.from({ length: 12 }, (_, i) => {
            const n = i + 1;
            const parcela = valor > 0 ? ` de ${MT.moeda(Math.floor(valor / n * 100) / 100)}` : "";
            return `<option value="${n}" ${n === escolhida ? "selected" : ""}>${n}x${parcela}</option>`;
        }).join("");

        ajuda.textContent = forma.value === "CartaoCredito"
            ? "Gera as parcelas a receber da operadora, a primeira em 30 dias."
            : "Gera as parcelas em aberto no Financeiro, a primeira vencendo em 30 dias.";
    }

    forma?.addEventListener("change", atualizarParcelas);
    formVendaEl?.addEventListener("reset", () => setTimeout(atualizarParcelas, 0));

    if (total) {
        new MutationObserver(atualizarParcelas).observe(total, { childList: true, characterData: true, subtree: true });
    }

    // ------------------------------------------------------
    // DETALHES DA VENDA
    // ------------------------------------------------------

    const modal = document.getElementById("modal-detalhe-venda");
    const titulo = document.getElementById("titulo-detalhe-venda");
    const conteudo = document.getElementById("conteudo-detalhe-venda");
    const acoesDetalhe = document.getElementById("acoes-detalhe-venda");
    const botaoIniciar = document.getElementById("iniciar-devolucao");

    const formDevolucao = document.getElementById("form-devolucao");
    const itensDevolucao = document.getElementById("itens-devolucao");
    const motivo = document.getElementById("motivo-devolucao");
    const reembolso = document.getElementById("reembolso-devolucao");
    const totalDevolucao = document.getElementById("total-devolucao");
    const mensagemDevolucao = document.getElementById("mensagem-devolucao");
    const botaoConfirmar = document.getElementById("confirmar-devolucao");

    let vendaAtual = null;

    const STATUS = {
        Concluida: '<span class="badge badge-ok">Concluída</span>',
        DevolvidaParcial: '<span class="badge badge-alerta">Devolução parcial</span>',
        Devolvida: '<span class="badge badge-vencida">Devolvida</span>'
    };

    async function abrirDetalheVenda(id) {
        conteudo.innerHTML = '<p class="mod-vazio">Carregando venda...</p>';
        formDevolucao.hidden = true;
        acoesDetalhe.hidden = false;
        MT.abrirModal(modal);

        try {
            vendaAtual = await MT.api(`/vendas/${id}`);
        } catch (erro) {
            conteudo.innerHTML = `<p class="mod-vazio">${MT.escapar(erro.message)}</p>`;
            botaoIniciar.hidden = true;
            return;
        }

        let contas = [];

        if (MT.administrador) {
            try {
                contas = await MT.api(`/financeiro?vendaId=${id}&status=`);
            } catch {
                contas = [];
            }
        }

        renderizarDetalhe(contas);
    }

    function renderizarDetalhe(contas) {
        const v = vendaAtual;
        titulo.textContent = `Venda #${v.id}`;

        const liquido = Number(v.valorTotal) - Number(v.valorDevolvido || 0);

        conteudo.innerHTML = `
            <div class="mod-cabecalho-nota">
                <div><span>Cliente</span><strong>${MT.escapar(v.cliente?.nome || "-")}</strong></div>
                <div><span>Data</span><strong>${MT.dataHora(v.criadoEm)}</strong></div>
                <div><span>Pagamento</span><strong>${MT.escapar(MT.nomeForma(v.formaPagamento))}${v.parcelas > 1 ? ` · ${v.parcelas}x` : ""}</strong></div>
                <div><span>Situação</span><strong>${STATUS[v.status] || MT.escapar(v.status)}</strong></div>
                <div><span>Total da venda</span><strong>${MT.moeda(v.valorTotal)}</strong></div>
                <div><span>Devolvido</span><strong>${MT.moeda(v.valorDevolvido)}</strong></div>
                <div><span>Valor líquido</span><strong>${MT.moeda(liquido)}</strong></div>
            </div>

            <div class="table-wrapper" tabindex="0" aria-label="Itens da venda">
                <table>
                    <thead><tr><th>Produto</th><th>Qtd</th><th>Devolvido</th><th>Preço unit.</th><th>Subtotal</th></tr></thead>
                    <tbody>${v.itens.map(i => `
                        <tr>
                            <td>${MT.escapar(i.produto?.nome || `Produto #${i.produtoId}`)}</td>
                            <td>${i.quantidade}</td>
                            <td>${i.quantidadeDevolvida || 0}</td>
                            <td class="valor">${MT.moeda(i.precoUnitario)}</td>
                            <td class="valor">${MT.moeda(i.subtotal)}</td>
                        </tr>`).join("")}
                    </tbody>
                </table>
            </div>

            ${v.devolucoes?.length ? `
                <h3>Devoluções</h3>
                ${v.devolucoes.map(d => `
                    <div class="mod-resumo-linha">
                        <span>#${d.id} · ${MT.dataHora(d.criadoEm)} · ${MT.escapar(d.usuarioNome || "")}<br>
                            <span class="texto-fraco">${MT.escapar(d.motivo)} — ${d.itens.map(i => `${i.quantidade}x ${MT.escapar(i.produto)}`).join(", ")}</span></span>
                        <strong>${MT.moeda(d.valorTotal)}</strong>
                    </div>`).join("")}` : ""}

            ${MT.administrador && contas.length ? `
                <h3>Contas a receber</h3>
                ${contas.map(c => `
                    <div class="mod-resumo-linha">
                        <span>${MT.escapar(c.descricao)} · vence ${MT.data(c.vencimento)}
                            <span class="badge ${c.status === "Paga" ? "badge-ok" : c.status === "Cancelada" ? "badge-cancelada" : c.vencida ? "badge-vencida" : "badge-aberta"}">
                                ${c.status === "Paga" ? (c.tipo === "Receber" ? "Recebida" : "Paga") : c.status === "Aberta" ? "Em aberto" : c.status}</span>
                            ${c.tipo === "Pagar" ? '<span class="texto-fraco">(reembolso ao cliente)</span>' : ""}</span>
                        <strong>${MT.moeda(c.valor)}</strong>
                    </div>`).join("")}
                <p class="mod-ajuda">Baixas e estornos são feitos na tela Financeiro.</p>` : ""}`;

        botaoIniciar.hidden = v.status === "Devolvida";
    }

    // ------------------------------------------------------
    // DEVOLUÇÃO
    // ------------------------------------------------------

    function iniciarDevolucao() {
        const v = vendaAtual;
        MT.mensagem(mensagemDevolucao, "");
        motivo.value = "";
        reembolso.value = "";

        itensDevolucao.innerHTML = v.itens.map(i => {
            const disponivel = i.quantidade - (i.quantidadeDevolvida || 0);
            const nome = MT.escapar(i.produto?.nome || `Produto #${i.produtoId}`);
            return `
                <tr data-item="${i.id}" data-preco="${i.precoUnitario}" data-max="${disponivel}">
                    <td>${nome}</td>
                    <td>${i.quantidade}</td>
                    <td>${i.quantidadeDevolvida || 0}</td>
                    <td>
                        <label class="sr-only" for="dev-${i.id}">Quantidade de ${nome} a devolver</label>
                        <input type="number" id="dev-${i.id}" class="qtd-devolver" min="0" max="${disponivel}" step="1"
                               value="0" ${disponivel === 0 ? "disabled" : ""}>
                        <button type="button" class="mod-botao devolver-tudo" ${disponivel === 0 ? "disabled" : ""}>Tudo (${disponivel})</button>
                    </td>
                    <td class="valor subtotal-dev">${MT.moeda(0)}</td>
                </tr>`;
        }).join("");

        atualizarTotal();
        acoesDetalhe.hidden = true;
        formDevolucao.hidden = false;
        itensDevolucao.querySelector(".qtd-devolver:not([disabled])")?.focus();
    }

    function atualizarTotal() {
        let soma = 0;

        itensDevolucao.querySelectorAll("tr[data-item]").forEach(tr => {
            const qtd = Number(tr.querySelector(".qtd-devolver").value) || 0;
            const subtotal = qtd * Number(tr.dataset.preco);
            tr.querySelector(".subtotal-dev").textContent = MT.moeda(subtotal);
            soma += subtotal;
        });

        totalDevolucao.textContent = MT.moeda(soma);
    }

    async function confirmarDevolucao(evento) {
        evento.preventDefault();

        const itens = [];

        for (const tr of itensDevolucao.querySelectorAll("tr[data-item]")) {
            const campo = tr.querySelector(".qtd-devolver");
            const qtd = Number(campo.value);
            const max = Number(tr.dataset.max);

            if (campo.value === "" || !Number.isInteger(qtd) || qtd < 0) {
                MT.mensagem(mensagemDevolucao, "Use números inteiros nas quantidades.");
                campo.focus();
                return;
            }

            if (qtd > max) {
                MT.mensagem(mensagemDevolucao, `Só é possível devolver até ${max} unidade(s) deste item.`);
                campo.focus();
                return;
            }

            if (qtd > 0) itens.push({ itemVendaId: Number(tr.dataset.item), quantidade: qtd });
        }

        if (itens.length === 0) {
            MT.mensagem(mensagemDevolucao, "Informe a quantidade de pelo menos um item.");
            return;
        }

        if (motivo.value.trim().length < 3) {
            MT.mensagem(mensagemDevolucao, "Informe o motivo da devolução.");
            motivo.focus();
            return;
        }

        botaoConfirmar.disabled = true;

        try {
            const resposta = await MT.api(`/vendas/${vendaAtual.id}/devolucoes`, {
                method: "POST",
                body: {
                    motivo: motivo.value.trim(),
                    itens,
                    formaReembolso: reembolso.value || null
                }
            });

            let texto = resposta.mensagem;

            if (resposta.reembolso) {
                texto += resposta.reembolso.pago
                    ? ` Reembolso de ${MT.moeda(resposta.reembolso.valor)} registrado como pago.`
                    : ` Reembolso de ${MT.moeda(resposta.reembolso.valor)} lançado em aberto no Financeiro.`;
            }

            MT.fecharModal(modal);

            if (typeof mostrarMensagem === "function" && typeof mensagemVendas !== "undefined") {
                mostrarMensagem(mensagemVendas, texto, "sucesso");
            }

            if (typeof carregarVendas === "function") await carregarVendas();
        } catch (erro) {
            MT.mensagem(mensagemDevolucao, erro.message);
        } finally {
            botaoConfirmar.disabled = false;
        }
    }

    botaoIniciar?.addEventListener("click", iniciarDevolucao);

    document.getElementById("cancelar-devolucao")?.addEventListener("click", () => {
        formDevolucao.hidden = true;
        acoesDetalhe.hidden = false;
    });

    itensDevolucao?.addEventListener("input", atualizarTotal);

    itensDevolucao?.addEventListener("click", evento => {
        const botao = evento.target.closest(".devolver-tudo");
        if (!botao) return;
        const tr = botao.closest("tr");
        tr.querySelector(".qtd-devolver").value = tr.dataset.max;
        atualizarTotal();
    });

    formDevolucao?.addEventListener("submit", confirmarDevolucao);

    MT.prepararModais();
    atualizarParcelas();

    window.abrirDetalheVenda = abrirDetalheVenda;
})();
