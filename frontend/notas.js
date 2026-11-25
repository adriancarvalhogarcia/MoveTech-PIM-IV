/* ==========================================================
   MOVETECH — NOTAS DE ENTRADA (somente administrador)
   1. Escolhe o XML da NF-e  → prévia (nada é gravado)
   2. Decide item a item: vincular a um produto existente ou
      cadastrar um novo (com preço calculado pelo markup)
   3. Confirma → estoque, custo médio e contas a pagar
   ========================================================== */

if (MT.exigirAdministrador()) {

    const TAMANHO_MAXIMO = 5 * 1024 * 1024;

    const tabela = document.getElementById("tabela-notas");
    const busca = document.getElementById("busca-nota");
    const mensagem = document.getElementById("mensagem-notas");

    const modalImportar = document.getElementById("modal-importar");
    const passoArquivo = document.getElementById("passo-arquivo");
    const passoPrevia = document.getElementById("passo-previa");
    const areaUpload = document.getElementById("area-upload");
    const arquivoXml = document.getElementById("arquivo-xml");
    const campoMarkup = document.getElementById("markup");
    const cabecalhoNota = document.getElementById("cabecalho-nota");
    const itensPrevia = document.getElementById("itens-previa");
    const duplicatasNota = document.getElementById("duplicatas-nota");
    const parcelasManuais = document.getElementById("parcelas-manuais");
    const notaParcelas = document.getElementById("nota-parcelas");
    const notaVencimento = document.getElementById("nota-vencimento");
    const mensagemImportar = document.getElementById("mensagem-importar");
    const botaoTrocar = document.getElementById("botao-trocar-arquivo");
    const botaoConfirmar = document.getElementById("botao-confirmar-nota");

    const modalDetalhe = document.getElementById("modal-detalhe-nota");
    const tituloDetalhe = document.getElementById("titulo-detalhe-nota");
    const conteudoDetalhe = document.getElementById("conteudo-detalhe-nota");

    let notas = [];
    let produtos = [];
    let xmlAtual = "";
    let previa = null;

    // ------------------------------------------------------
    // LISTA
    // ------------------------------------------------------

    function documento(valor) {
        const d = String(valor || "").replace(/\D/g, "");
        if (d.length === 14) return d.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, "$1.$2.$3/$4-$5");
        if (d.length === 11) return d.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})$/, "$1.$2.$3-$4");
        return d;
    }

    async function carregar() {
        try {
            notas = await MT.api("/notas-entrada");
            renderizar();
        } catch (erro) {
            tabela.innerHTML = `<tr><td colspan="7" class="mod-vazio">${MT.escapar(erro.message)}</td></tr>`;
        }
    }

    function renderizar() {
        const termo = busca.value.trim().toLowerCase();
        const lista = notas.filter(n =>
            !termo ||
            String(n.numero).includes(termo) ||
            n.fornecedor.toLowerCase().includes(termo) ||
            n.chaveAcesso.includes(termo.replace(/\D/g, "") || "~"));

        if (lista.length === 0) {
            tabela.innerHTML = `<tr><td colspan="7" class="mod-vazio">${
                notas.length ? "Nenhuma nota encontrada." : "Nenhuma nota lançada ainda. Use “Importar XML”."
            }</td></tr>`;
            return;
        }

        tabela.innerHTML = lista.map(n => `
            <tr>
                <td><strong>Nº ${MT.escapar(n.numero)}</strong><br><span class="texto-fraco">Série ${MT.escapar(n.serie)}</span></td>
                <td>${MT.escapar(n.fornecedor)}<br><span class="texto-fraco">${documento(n.fornecedorDocumento)}</span></td>
                <td>${MT.data(n.dataEmissao)}</td>
                <td>${n.quantidadeItens}</td>
                <td class="valor">${MT.moeda(n.valorTotal)}</td>
                <td>${MT.dataHora(n.criadoEm)}<br><span class="texto-fraco">${MT.escapar(n.usuarioNome || "")}</span></td>
                <td><button type="button" class="mod-botao" data-nota="${n.id}">Detalhes</button></td>
            </tr>`).join("");
    }

    // ------------------------------------------------------
    // IMPORTAÇÃO — PASSO 1
    // ------------------------------------------------------

    async function abrirImportacao() {
        xmlAtual = "";
        previa = null;
        arquivoXml.value = "";
        mostrarPasso("arquivo");
        MT.mensagem(mensagemImportar, "");
        MT.abrirModal(modalImportar);

        try {
            produtos = await MT.api("/produtos");
        } catch (erro) {
            MT.mensagem(mensagemImportar, erro.message);
        }
    }

    function mostrarPasso(passo) {
        passoArquivo.hidden = passo !== "arquivo";
        passoPrevia.hidden = passo !== "previa";
        botaoTrocar.hidden = passo !== "previa";
        botaoConfirmar.hidden = passo !== "previa";
    }

    async function lerArquivo(arquivo) {
        MT.mensagem(mensagemImportar, "");

        if (!arquivo) return;

        if (!/\.xml$/i.test(arquivo.name)) {
            MT.mensagem(mensagemImportar, "Escolha um arquivo .xml da NF-e.");
            return;
        }

        if (arquivo.size > TAMANHO_MAXIMO) {
            MT.mensagem(mensagemImportar, "O arquivo passa de 5 MB. Confira se é mesmo o XML da nota.");
            return;
        }

        xmlAtual = await arquivo.text();
        await gerarPrevia();
    }

    async function gerarPrevia() {
        const markup = Number(campoMarkup.value);

        if (!(markup >= 0 && markup <= 1000)) {
            MT.mensagem(mensagemImportar, "O markup deve estar entre 0% e 1000%.");
            return;
        }

        MT.mensagem(mensagemImportar, "Lendo a nota...", "info");

        try {
            previa = await MT.api("/notas-entrada/previa", {
                method: "POST",
                body: { xml: xmlAtual, markupPercentual: markup }
            });
        } catch (erro) {
            MT.mensagem(mensagemImportar, erro.message);
            return;
        }

        MT.mensagem(mensagemImportar, "");

        if (previa.jaImportada) {
            MT.mensagem(mensagemImportar,
                `A nota ${previa.numero} deste fornecedor já foi lançada. Não é possível importar de novo.`);
            return;
        }

        renderizarPrevia();
        mostrarPasso("previa");
    }

    // ------------------------------------------------------
    // IMPORTAÇÃO — PASSO 2 (PRÉVIA)
    // ------------------------------------------------------

    function opcoesProdutos(selecionado) {
        return produtos
            .slice()
            .sort((a, b) => a.nome.localeCompare(b.nome))
            .map(p => `<option value="${p.id}" ${p.id === selecionado ? "selected" : ""}>
                ${MT.escapar(p.nome)}${p.ativo ? "" : " (inativo)"} — estoque ${p.quantidadeEstoque}
            </option>`).join("");
    }

    function categorias() {
        return [...new Set(produtos.map(p => p.categoria).filter(Boolean))].sort();
    }

    function renderizarPrevia() {
        const f = previa.fornecedor;

        cabecalhoNota.innerHTML = `
            <div><span>Nota / série</span><strong>${MT.escapar(previa.numero)} / ${MT.escapar(previa.serie)}</strong></div>
            <div><span>Emissão</span><strong>${MT.data(previa.dataEmissao)}</strong></div>
            <div><span>Fornecedor ${f.cadastrado ? "" : "(será cadastrado)"}</span>
                 <strong>${MT.escapar(f.razaoSocial)}</strong>
                 <span>${documento(f.documento)}</span></div>
            <div><span>Valor total</span><strong>${MT.moeda(previa.valorTotal)}</strong></div>
            <div style="grid-column:1/-1"><span>Chave de acesso</span><strong>${MT.escapar(previa.chaveAcesso)}</strong></div>`;

        const listaCategorias = categorias();

        itensPrevia.innerHTML = previa.itens.map(item => {
            const sugerido = item.produtoSugerido;
            const vincular = item.acaoSugerida === "vincular";

            return `
            <tr data-item="${item.numeroItem}" class="${vincular ? "" : "mod-item-novo"}">
                <td>${item.numeroItem}</td>
                <td>
                    <strong>${MT.escapar(item.descricao)}</strong><br>
                    <span class="texto-fraco">Cód. ${MT.escapar(item.codigo)}${item.codigoBarras ? " · EAN " + MT.escapar(item.codigoBarras) : ""}</span>
                    ${sugerido ? `<br><span class="badge badge-ok">Reconhecido pelo ${MT.escapar(sugerido.motivo)}</span>` : ""}
                </td>
                <td>
                    ${item.quantidade}${item.unidade ? " " + MT.escapar(item.unidade) : ""}
                    ${item.quantidadeInteira ? "" : '<br><span class="badge badge-vencida">Fracionada</span>'}
                </td>
                <td class="valor">${MT.moeda(item.custoUnitario)}<br>
                    <span class="texto-fraco">total ${MT.moeda(item.custoTotal)}</span></td>
                <td>
                    <label class="sr-only" for="acao-${item.numeroItem}">Ação para o item ${item.numeroItem}</label>
                    <select id="acao-${item.numeroItem}" class="campo-acao">
                        <option value="vincular" ${vincular ? "selected" : ""}>Somar a produto existente</option>
                        <option value="criar" ${vincular ? "" : "selected"}>Cadastrar produto novo</option>
                    </select>
                </td>
                <td>
                    <div class="bloco-vincular" ${vincular ? "" : "hidden"}>
                        <label class="sr-only" for="produto-${item.numeroItem}">Produto do MoveTech</label>
                        <select id="produto-${item.numeroItem}" class="campo-produto">
                            <option value="">Selecione o produto</option>
                            ${opcoesProdutos(sugerido?.id)}
                        </select>
                        <p class="mod-ajuda info-vinculo"></p>
                    </div>
                    <div class="bloco-criar mod-form-grid" ${vincular ? "hidden" : ""}>
                        <div class="mod-campo mod-campo-full">
                            <label for="nome-${item.numeroItem}">Nome</label>
                            <input id="nome-${item.numeroItem}" class="campo-nome" maxlength="120"
                                   value="${MT.escapar(item.descricao.slice(0, 120))}">
                        </div>
                        <div class="mod-campo">
                            <label for="categoria-${item.numeroItem}">Categoria</label>
                            <input id="categoria-${item.numeroItem}" class="campo-categoria" maxlength="100"
                                   list="lista-categorias" value="Geral">
                        </div>
                        <div class="mod-campo">
                            <label for="preco-${item.numeroItem}">Preço de venda</label>
                            <input id="preco-${item.numeroItem}" class="campo-preco" type="number" min="0.01" step="0.01"
                                   value="${item.precoSugerido}">
                            <p class="mod-ajuda info-margem"></p>
                        </div>
                        <div class="mod-campo">
                            <label for="minimo-${item.numeroItem}">Estoque mínimo</label>
                            <input id="minimo-${item.numeroItem}" class="campo-minimo" type="number" min="0" step="1" value="0">
                        </div>
                    </div>
                </td>
            </tr>`;
        }).join("");

        // Sugestões de categoria (datalist fica fora da tabela).
        let lista = document.getElementById("lista-categorias");
        if (!lista) {
            lista = document.createElement("datalist");
            lista.id = "lista-categorias";
            document.body.appendChild(lista);
        }
        lista.innerHTML = listaCategorias.map(c => `<option value="${MT.escapar(c)}">`).join("");

        previa.itens.forEach(item => atualizarLinha(item.numeroItem));

        // Contas a pagar
        if (previa.duplicatas.length > 0) {
            parcelasManuais.hidden = true;
            duplicatasNota.innerHTML =
                `<p class="texto-fraco">A nota traz ${previa.duplicatas.length} duplicata(s); as contas a pagar seguirão estes vencimentos:</p>` +
                previa.duplicatas.map(d => `
                    <div class="mod-resumo-linha">
                        <span>Duplicata ${MT.escapar(d.numero)} · vence ${MT.data(d.vencimento)}</span>
                        <strong>${MT.moeda(d.valor)}</strong>
                    </div>`).join("");
        } else {
            duplicatasNota.innerHTML =
                '<p class="texto-fraco">A nota não traz duplicatas. Informe como será pago ao fornecedor:</p>';
            parcelasManuais.hidden = false;
            notaParcelas.value = 1;
            notaVencimento.value = MT.somarDias(String(previa.dataEmissao).slice(0, 10), 30);
        }

        const fracionado = previa.itens.some(i => !i.quantidadeInteira);
        botaoConfirmar.disabled = fracionado;

        if (fracionado) {
            MT.mensagem(mensagemImportar,
                "Há item com quantidade fracionada. O estoque do MoveTech trabalha com unidades inteiras.");
        }
    }

    function linha(numero) {
        return itensPrevia.querySelector(`tr[data-item="${numero}"]`);
    }

    function atualizarLinha(numero) {
        const tr = linha(numero);
        const item = previa.itens.find(i => i.numeroItem === numero);
        const acao = tr.querySelector(".campo-acao").value;

        tr.querySelector(".bloco-vincular").hidden = acao !== "vincular";
        tr.querySelector(".bloco-criar").hidden = acao !== "criar";
        tr.classList.toggle("mod-item-novo", acao === "criar");

        if (acao === "vincular") {
            const produto = produtos.find(p => p.id === Number(tr.querySelector(".campo-produto").value));
            const info = tr.querySelector(".info-vinculo");

            if (produto) {
                const estoque = Math.max(Number(produto.quantidadeEstoque), 0);
                const custoAtual = Number(produto.custoMedio) > 0 ? Number(produto.custoMedio) : item.custoUnitario;
                const novoCusto = (estoque * custoAtual + item.quantidade * item.custoUnitario) / (estoque + item.quantidade);
                info.textContent =
                    `Estoque ${produto.quantidadeEstoque} → ${produto.quantidadeEstoque + item.quantidade} · ` +
                    `custo médio ${MT.moeda(custoAtual)} → ${MT.moeda(novoCusto)} · preço de venda ${MT.moeda(produto.preco)}`;
            } else {
                info.textContent = "Escolha o produto que vai receber esta entrada.";
            }
        } else {
            const preco = Number(tr.querySelector(".campo-preco").value);
            const margem = item.custoUnitario > 0 ? ((preco / item.custoUnitario) - 1) * 100 : 0;
            tr.querySelector(".info-margem").textContent =
                preco > 0 ? `Margem de ${margem.toFixed(1).replace(".", ",")}% sobre o custo` : "";
        }
    }

    function recalcularPrecos() {
        const markup = Number(campoMarkup.value) || 0;
        if (!previa) return;

        previa.itens.forEach(item => {
            const campo = linha(item.numeroItem)?.querySelector(".campo-preco");
            if (campo && !campo.dataset.editado) {
                campo.value = Math.max(0.01, item.custoUnitario * (1 + markup / 100)).toFixed(2);
                atualizarLinha(item.numeroItem);
            }
        });
    }

    function montarDecisoes() {
        return previa.itens.map(item => {
            const tr = linha(item.numeroItem);
            const acao = tr.querySelector(".campo-acao").value;

            if (acao === "vincular") {
                const produtoId = Number(tr.querySelector(".campo-produto").value);
                if (!produtoId) throw new Error(`Item ${item.numeroItem}: escolha o produto para somar a entrada.`);
                return { numeroItem: item.numeroItem, acao, produtoId };
            }

            const nome = tr.querySelector(".campo-nome").value.trim();
            const categoria = tr.querySelector(".campo-categoria").value.trim() || "Geral";
            const precoVenda = Number(tr.querySelector(".campo-preco").value);
            const estoqueMinimo = Number(tr.querySelector(".campo-minimo").value);

            if (nome.length < 2) throw new Error(`Item ${item.numeroItem}: informe o nome do produto.`);
            if (!(precoVenda > 0)) throw new Error(`Item ${item.numeroItem}: informe um preço de venda maior que zero.`);
            if (!Number.isInteger(estoqueMinimo) || estoqueMinimo < 0)
                throw new Error(`Item ${item.numeroItem}: estoque mínimo deve ser um número inteiro.`);

            if (precoVenda < item.custoUnitario &&
                !window.confirm(`O preço de "${nome}" está abaixo do custo (${MT.moeda(item.custoUnitario)}). Continuar mesmo assim?`)) {
                throw new Error("Revise o preço de venda.");
            }

            return { numeroItem: item.numeroItem, acao, nome, categoria, precoVenda, estoqueMinimo };
        });
    }

    async function confirmar() {
        let itens;

        try {
            itens = montarDecisoes();
        } catch (erro) {
            MT.mensagem(mensagemImportar, erro.message);
            return;
        }

        const corpo = {
            xml: xmlAtual,
            markupPercentual: Number(campoMarkup.value) || 0,
            itens
        };

        if (previa.duplicatas.length === 0) {
            const parcelas = Number(notaParcelas.value);
            if (!Number.isInteger(parcelas) || parcelas < 1 || parcelas > 24) {
                MT.mensagem(mensagemImportar, "Parcelas devem estar entre 1 e 24.");
                return;
            }
            if (!notaVencimento.value) {
                MT.mensagem(mensagemImportar, "Informe o primeiro vencimento.");
                return;
            }
            corpo.parcelas = parcelas;
            corpo.primeiroVencimento = notaVencimento.value;
        }

        botaoConfirmar.disabled = true;
        botaoConfirmar.textContent = "Lançando...";

        try {
            const resposta = await MT.api("/notas-entrada", { method: "POST", body: corpo });
            MT.fecharModal(modalImportar);
            MT.mensagem(mensagem, resposta.mensagem, "sucesso");
            await carregar();
        } catch (erro) {
            MT.mensagem(mensagemImportar, erro.message);
        } finally {
            botaoConfirmar.disabled = false;
            botaoConfirmar.textContent = "Confirmar entrada";
        }
    }

    // ------------------------------------------------------
    // DETALHES
    // ------------------------------------------------------

    async function abrirDetalhe(id) {
        conteudoDetalhe.innerHTML = '<p class="mod-vazio">Carregando...</p>';
        MT.abrirModal(modalDetalhe);

        try {
            const { nota, contasPagar } = await MT.api(`/notas-entrada/${id}`);
            tituloDetalhe.textContent = `Nota ${nota.numero} / série ${nota.serie}`;

            conteudoDetalhe.innerHTML = `
                <div class="mod-cabecalho-nota">
                    <div><span>Fornecedor</span><strong>${MT.escapar(nota.fornecedor.razaoSocial)}</strong><span>${documento(nota.fornecedor.documento)}</span></div>
                    <div><span>Emissão</span><strong>${MT.data(nota.dataEmissao)}</strong></div>
                    <div><span>Valor total</span><strong>${MT.moeda(nota.valorTotal)}</strong></div>
                    <div><span>Lançada por</span><strong>${MT.escapar(nota.usuarioNome || "-")}</strong><span>${MT.dataHora(nota.criadoEm)}</span></div>
                    <div style="grid-column:1/-1"><span>Chave de acesso</span><strong>${MT.escapar(nota.chaveAcesso)}</strong></div>
                </div>
                <div class="table-wrapper" tabindex="0">
                    <table>
                        <thead><tr><th>Produto</th><th>Qtd</th><th>Custo unit.</th><th>Custo total</th><th></th></tr></thead>
                        <tbody>${nota.itens.map(i => `
                            <tr>
                                <td>${MT.escapar(i.produto)}<br><span class="texto-fraco">Na nota: ${MT.escapar(i.descricao)}</span></td>
                                <td>${i.quantidade}</td>
                                <td class="valor">${MT.moeda(i.custoUnitario)}</td>
                                <td class="valor">${MT.moeda(i.custoTotal)}</td>
                                <td>${i.produtoCriado ? '<span class="badge badge-ok">Cadastrado pela nota</span>' : ""}</td>
                            </tr>`).join("")}
                        </tbody>
                    </table>
                </div>
                <h3>Contas a pagar geradas</h3>
                ${contasPagar.map(c => `
                    <div class="mod-resumo-linha">
                        <span>Parcela ${c.numeroParcela}/${c.totalParcelas} · vence ${MT.data(c.vencimento)}
                            <span class="badge ${c.status === "Paga" ? "badge-ok" : "badge-aberta"}">${c.status}</span></span>
                        <strong>${MT.moeda(c.valor)}</strong>
                    </div>`).join("")}
                <p class="mod-ajuda">Para pagar as parcelas, use a tela Financeiro.</p>`;
        } catch (erro) {
            conteudoDetalhe.innerHTML = `<p class="mod-vazio">${MT.escapar(erro.message)}</p>`;
        }
    }

    // ------------------------------------------------------
    // EVENTOS
    // ------------------------------------------------------

    document.getElementById("botao-importar").addEventListener("click", abrirImportacao);
    busca.addEventListener("input", renderizar);
    arquivoXml.addEventListener("change", () => lerArquivo(arquivoXml.files[0]));
    botaoTrocar.addEventListener("click", () => { arquivoXml.value = ""; mostrarPasso("arquivo"); MT.mensagem(mensagemImportar, ""); });
    botaoConfirmar.addEventListener("click", confirmar);
    campoMarkup.addEventListener("input", recalcularPrecos);

    ["dragenter", "dragover"].forEach(tipo => areaUpload.addEventListener(tipo, evento => {
        evento.preventDefault();
        areaUpload.classList.add("arrastando");
    }));

    ["dragleave", "drop"].forEach(tipo => areaUpload.addEventListener(tipo, evento => {
        evento.preventDefault();
        areaUpload.classList.remove("arrastando");
    }));

    areaUpload.addEventListener("drop", evento => lerArquivo(evento.dataTransfer.files[0]));

    itensPrevia.addEventListener("change", evento => {
        const tr = evento.target.closest("tr[data-item]");
        if (tr) atualizarLinha(Number(tr.dataset.item));
    });

    itensPrevia.addEventListener("input", evento => {
        if (evento.target.classList.contains("campo-preco")) {
            evento.target.dataset.editado = "1";
            atualizarLinha(Number(evento.target.closest("tr").dataset.item));
        }
    });

    tabela.addEventListener("click", evento => {
        const botao = evento.target.closest("[data-nota]");
        if (botao) abrirDetalhe(Number(botao.dataset.nota));
    });

    MT.prepararModais();
    carregar();
}
