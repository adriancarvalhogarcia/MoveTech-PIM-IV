/* ==========================================================
   MOVETECH — USUÁRIOS (somente administrador)
   Cadastro, edição de perfil/situação e redefinição de senha.
   ========================================================== */

if (MT.exigirAdministrador()) {

    const tabela = document.getElementById("tabela-usuarios");
    const busca = document.getElementById("busca-usuario");
    const contagem = document.getElementById("contagem-usuarios");
    const mensagem = document.getElementById("mensagem-usuarios");

    const modalUsuario = document.getElementById("modal-usuario");
    const formUsuario = document.getElementById("form-usuario");
    const tituloModal = document.getElementById("titulo-modal-usuario");
    const campoId = document.getElementById("usuario-id");
    const campoNome = document.getElementById("usuario-nome-campo");
    const campoEmail = document.getElementById("usuario-email");
    const campoPerfil = document.getElementById("usuario-perfil-campo");
    const campoAtivo = document.getElementById("usuario-ativo");
    const campoSenha = document.getElementById("usuario-senha");
    const grupoSenha = document.getElementById("grupo-senha");
    const mensagemForm = document.getElementById("mensagem-form-usuario");
    const botaoSalvar = document.getElementById("salvar-usuario");

    const modalSenha = document.getElementById("modal-senha");
    const formSenha = document.getElementById("form-senha");
    const senhaId = document.getElementById("senha-usuario-id");
    const senhaNome = document.getElementById("senha-usuario-nome");
    const novaSenha = document.getElementById("nova-senha");
    const confirmarSenha = document.getElementById("confirmar-senha");
    const mensagemSenha = document.getElementById("mensagem-form-senha");

    const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

    let usuarios = [];

    async function carregar() {
        try {
            usuarios = await MT.api("/usuarios");
            renderizar();
        } catch (erro) {
            tabela.innerHTML = `<tr><td colspan="6" class="mod-vazio">${MT.escapar(erro.message)}</td></tr>`;
        }
    }

    function renderizar() {
        const termo = busca.value.trim().toLowerCase();
        const lista = usuarios.filter(u =>
            !termo ||
            u.nome.toLowerCase().includes(termo) ||
            u.email.toLowerCase().includes(termo));

        const admins = usuarios.filter(u => u.ativo && u.perfil === "Administrador").length;
        contagem.textContent = `${usuarios.length} usuário(s) · ${admins} administrador(es) ativo(s)`;

        if (lista.length === 0) {
            tabela.innerHTML = '<tr><td colspan="6" class="mod-vazio">Nenhum usuário encontrado.</td></tr>';
            return;
        }

        const meuId = Number(MT.usuario?.id);

        tabela.innerHTML = lista.map(u => `
            <tr>
                <td>
                    <strong>${MT.escapar(u.nome)}</strong>
                    ${u.id === meuId ? '<br><span class="texto-fraco">Você</span>' : ""}
                </td>
                <td>${MT.escapar(u.email)}</td>
                <td>
                    <span class="badge ${u.perfil === "Administrador" ? "badge-alerta" : "badge-aberta"}">
                        ${MT.escapar(MT.nomePerfil(u.perfil))}
                    </span>
                </td>
                <td>
                    <span class="badge ${u.ativo ? "badge-ok" : "badge-cancelada"}">
                        ${u.ativo ? "Ativo" : "Inativo"}
                    </span>
                </td>
                <td>${MT.dataHora(u.criadoEm)}</td>
                <td>
                    <div class="mod-acoes">
                        <button type="button" class="mod-botao" data-editar="${u.id}"
                                aria-label="Editar ${MT.escapar(u.nome)}">Editar</button>
                        <button type="button" class="mod-botao" data-senha="${u.id}"
                                aria-label="Redefinir senha de ${MT.escapar(u.nome)}">Redefinir senha</button>
                    </div>
                </td>
            </tr>`).join("");
    }

    function abrirCadastro(usuario = null) {
        formUsuario.reset();
        MT.mensagem(mensagemForm, "");

        campoId.value = usuario?.id || "";
        tituloModal.textContent = usuario ? "Editar usuário" : "Novo usuário";
        campoNome.value = usuario?.nome || "";
        campoEmail.value = usuario?.email || "";
        campoPerfil.value = usuario?.perfil === "Administrador" ? "Administrador" : "Funcionario";
        campoAtivo.value = String(usuario ? usuario.ativo : true);

        // Senha só no cadastro; na edição usa "Redefinir senha".
        grupoSenha.hidden = Boolean(usuario);
        campoSenha.required = !usuario;

        // O próprio administrador não pode se rebaixar nem se desativar.
        const souEu = usuario && usuario.id === Number(MT.usuario?.id);
        campoPerfil.disabled = Boolean(souEu);
        campoAtivo.disabled = Boolean(souEu);

        MT.abrirModal(modalUsuario);
    }

    function validar() {
        const nome = campoNome.value.trim();
        const email = campoEmail.value.trim();

        if (nome.length < 3) return "Informe o nome completo (mínimo de 3 letras).";
        if (!EMAIL.test(email)) return "Informe um e-mail válido.";
        if (!campoId.value && campoSenha.value.length < 6) return "A senha deve ter pelo menos 6 caracteres.";

        const duplicado = usuarios.some(u =>
            u.email.toLowerCase() === email.toLowerCase() && String(u.id) !== campoId.value);

        if (duplicado) return "Já existe um usuário com este e-mail.";

        return null;
    }

    async function salvar(evento) {
        evento.preventDefault();

        const erro = validar();

        if (erro) {
            MT.mensagem(mensagemForm, erro);
            return;
        }

        const id = campoId.value;
        const corpo = {
            nome: campoNome.value.trim(),
            email: campoEmail.value.trim(),
            perfil: campoPerfil.value,
            ativo: campoAtivo.value === "true"
        };

        botaoSalvar.disabled = true;

        try {
            if (id) {
                await MT.api(`/usuarios/${id}`, { method: "PUT", body: corpo });
            } else {
                await MT.api("/usuarios", {
                    method: "POST",
                    body: { nome: corpo.nome, email: corpo.email, perfil: corpo.perfil, senha: campoSenha.value }
                });
            }

            MT.fecharModal(modalUsuario);
            MT.mensagem(mensagem, id ? "Usuário atualizado." : "Usuário cadastrado.", "sucesso");
            await carregar();
        } catch (falha) {
            MT.mensagem(mensagemForm, falha.message);
        } finally {
            botaoSalvar.disabled = false;
        }
    }

    function abrirSenha(usuario) {
        formSenha.reset();
        MT.mensagem(mensagemSenha, "");
        senhaId.value = usuario.id;
        senhaNome.textContent = `Usuário: ${usuario.nome} (${usuario.email})`;
        MT.abrirModal(modalSenha);
    }

    async function salvarSenha(evento) {
        evento.preventDefault();

        if (novaSenha.value.length < 6) {
            MT.mensagem(mensagemSenha, "A senha deve ter pelo menos 6 caracteres.");
            return;
        }

        if (novaSenha.value !== confirmarSenha.value) {
            MT.mensagem(mensagemSenha, "As senhas não conferem.");
            return;
        }

        try {
            const resposta = await MT.api(`/usuarios/${senhaId.value}/senha`, {
                method: "PUT",
                body: { novaSenha: novaSenha.value }
            });
            MT.fecharModal(modalSenha);
            MT.mensagem(mensagem, resposta?.mensagem || "Senha redefinida.", "sucesso");
        } catch (falha) {
            MT.mensagem(mensagemSenha, falha.message);
        }
    }

    document.getElementById("botao-novo-usuario").addEventListener("click", () => abrirCadastro());
    busca.addEventListener("input", renderizar);
    formUsuario.addEventListener("submit", salvar);
    formSenha.addEventListener("submit", salvarSenha);

    tabela.addEventListener("click", evento => {
        const editar = evento.target.closest("[data-editar]");
        const senha = evento.target.closest("[data-senha]");
        const alvo = usuarios.find(u => u.id === Number((editar || senha)?.dataset.editar || (editar || senha)?.dataset.senha));
        if (!alvo) return;
        if (editar) abrirCadastro(alvo);
        else abrirSenha(alvo);
    });

    MT.prepararModais();
    carregar();
}
