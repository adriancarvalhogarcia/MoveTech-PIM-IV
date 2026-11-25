import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../core/utils/validadores.dart';
import '../../data/models/cliente.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../services/sync_service.dart';
import '../widgets/componentes.dart';

/// Cadastro (POST /api/clientes) e edição (PUT /api/clientes/{id}).
class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key, this.cliente});

  /// null = novo cliente.
  final Cliente? cliente;

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _cpf;
  late final TextEditingController _telefone;
  late final TextEditingController _email;
  late final TextEditingController _endereco;
  late bool _ativo;
  bool _salvando = false;
  bool _tentouSalvar = false;
  String? _erro;

  bool get _edicao => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nome = TextEditingController(text: c?.nome ?? '');
    _cpf = TextEditingController(text: c == null ? '' : Formatadores.cpf(c.cpf));
    _telefone = TextEditingController(
      text: c?.telefone == null ? '' : Formatadores.telefone(c!.telefone),
    );
    _email = TextEditingController(text: c?.email ?? '');
    _endereco = TextEditingController(text: c?.endereco ?? '');
    _ativo = c?.ativo ?? true;
  }

  @override
  void dispose() {
    for (final c in [_nome, _cpf, _telefone, _email, _endereco]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    if (_salvando) return; // evita envio duplicado por toque duplo
    if (!_form.currentState!.validate()) {
      setState(() => _tentouSalvar = true);
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final repo = context.read<ClienteRepository>();
    final sync = context.read<SyncService>();
    try {
      if (_edicao) {
        await repo.atualizar(
          widget.cliente!.id,
          nome: _nome.text,
          cpf: _cpf.text,
          telefone: _telefone.text,
          email: _email.text,
          endereco: _endereco.text,
          ativo: _ativo,
        );
      } else {
        await repo.criar(
          nome: _nome.text,
          cpf: _cpf.text,
          telefone: _telefone.text,
          email: _email.text,
          endereco: _endereco.text,
        );
      }
      // A tela Nova venda e a lista de clientes recarregam na hora.
      sync.notificarAlteracaoDados();
      if (!mounted) return;
      mostrarMensagem(context, _edicao ? 'Cliente atualizado.' : 'Cliente cadastrado.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } on SemConexaoException catch (e) {
      setState(() => _erro = '${e.mensagem}\nO cliente não foi salvo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edicao ? 'Editar cliente' : 'Novo cliente')),
      body: SafeArea(
        child: Form(
          key: _form,
          // Depois da primeira tentativa de salvar, os erros somem
          // assim que o usuário corrige o campo.
          autovalidateMode: _tentouSalvar
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nome completo *'),
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                validator: Validadores.nomePessoa,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cpf,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _MascaraCpf(),
                ],
                decoration: const InputDecoration(
                  labelText: 'CPF *',
                  hintText: '000.000.000-00',
                ),
                validator: (v) {
                  final erro = Validadores.cpf(v);
                  if (erro != null) return erro;
                  final existente = context
                      .read<ClienteRepository>()
                      .buscarPorCpfNoCache(v ?? '', ignorarId: widget.cliente?.id);
                  return existente == null
                      ? null
                      : 'CPF já cadastrado para ${existente.nome}.';
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telefone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _MascaraTelefone(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(11) 99999-9999',
                ),
                validator: Validadores.telefone,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  LengthLimitingTextInputFormatter(150),
                ],
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) =>
                    Validadores.email(v, obrigatorio: false) ??
                    Validadores.tamanhoMaximo(v, 150),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _endereco,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                inputFormatters: [LengthLimitingTextInputFormatter(250)],
                decoration: const InputDecoration(labelText: 'Endereço'),
                validator: (v) => Validadores.tamanhoMaximo(v, 250),
              ),
              if (_edicao) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cliente ativo'),
                  subtitle: const Text(
                    'Clientes inativos não aparecem para novas vendas.',
                    style: TextStyle(color: Cores.textoSecundario),
                  ),
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                ),
              ],
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(_erro!, style: const TextStyle(color: Cores.erro)),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_edicao ? 'Salvar alterações' : 'Cadastrar cliente'),
              ),
              const SizedBox(height: 8),
              const Text(
                '* Campos obrigatórios',
                style: TextStyle(color: Cores.textoSecundario, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formata o telefone enquanto o usuário digita: (11) 98765-4321
class _MascaraTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = Formatadores.telefone(newValue.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Formata o CPF enquanto o usuário digita: 00000000000 -> 000.000.000-00
class _MascaraCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text;
    final buffer = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(d[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
