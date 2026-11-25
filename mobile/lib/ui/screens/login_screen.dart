import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validadores.dart';
import '../../data/local/armazenamento_local.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _focoSenha = FocusNode();

  bool _ocultarSenha = true;
  bool _entrando = false;
  bool _tentouEntrar = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _erro = auth.aviso;
    auth.limparAviso();
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _focoSenha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (_entrando) return; // evita envio duplicado por toque duplo
    if (!_form.currentState!.validate()) {
      setState(() => _tentouEntrar = true);
      return;
    }

    setState(() {
      _entrando = true;
      _erro = null;
    });

    try {
      await context.read<AuthService>().entrar(_email.text, _senha.text);
      // O _PortaoAutenticacao troca para a HomeShell automaticamente.
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } on SemConexaoException catch (e) {
      setState(() => _erro =
          '${e.mensagem}\nConfira o endereço do servidor no ícone de engrenagem.');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  Future<void> _configurarServidor() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _DialogoServidor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Configurar endereço do servidor',
            icon: const Icon(Icons.settings_rounded),
            onPressed: _configurarServidor,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                autovalidateMode: _tentouEntrar
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Marca(),
                    const SizedBox(height: 36),
                    const Text(
                      'Entrar',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Use o mesmo e-mail e senha do sistema web.',
                      style: TextStyle(color: Cores.textoSecundario),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        LengthLimitingTextInputFormatter(150),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) => Validadores.email(v),
                      onFieldSubmitted: (_) => _focoSenha.requestFocus(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _senha,
                      focusNode: _focoSenha,
                      obscureText: _ocultarSenha,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                          icon: Icon(_ocultarSenha
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                      validator: Validadores.senha,
                      onFieldSubmitted: (_) => _entrar(),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Cores.erro.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Cores.erro.withAlpha(90)),
                          ),
                          child: Text(_erro!, style: const TextStyle(color: Cores.erro)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _entrando ? null : _entrar,
                      child: _entrando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MoveTech, gestão para lojas de móveis',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Cores.verde,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.chair_rounded, color: Cores.verdeEscuro, size: 30),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MoveTech',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Text('Gestão para lojas de móveis',
                  style: TextStyle(color: Cores.textoSecundario)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Permite trocar o endereço da API e testar a conexão.
class _DialogoServidor extends StatefulWidget {
  const _DialogoServidor();

  @override
  State<_DialogoServidor> createState() => _DialogoServidorState();
}

class _DialogoServidorState extends State<_DialogoServidor> {
  late final TextEditingController _url;
  String? _resultado;
  bool _ok = false;
  bool _testando = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: context.read<ArmazenamentoLocal>().urlApi);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  /// Valida o endereço digitado; mostra o erro e devolve false se inválido.
  bool _urlValida() {
    final erro = Validadores.urlApi(_url.text);
    setState(() {
      _ok = false;
      _resultado = erro;
    });
    return erro == null;
  }

  Future<void> _testar() async {
    if (!_urlValida()) return;
    final local = context.read<ArmazenamentoLocal>();
    final api = context.read<ApiClient>();
    final anterior = local.urlApi;
    await local.salvarUrlApi(_url.text);
    setState(() {
      _testando = true;
      _resultado = null;
    });
    try {
      // Rota protegida sem token: se a API responder 401, ela está no ar.
      await api.get('/produtos', autenticado: false);
      _ok = true;
      _resultado = 'Servidor encontrado.';
    } on ApiException catch (e) {
      _ok = e.statusCode == 401;
      _resultado = _ok ? 'Servidor encontrado.' : 'Resposta inesperada: ${e.mensagem}';
    } on SemConexaoException catch (e) {
      _ok = false;
      _resultado = e.mensagem;
    } finally {
      if (!_ok) await local.salvarUrlApi(anterior);
      if (mounted) setState(() => _testando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Servidor da API'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Endereço da API'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Emulador Android: http://10.0.2.2:5071/api\n'
            'Celular: http://IP-DO-COMPUTADOR:5071/api',
            style: TextStyle(color: Cores.textoSecundario, fontSize: 12),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 10),
            Text(
              _resultado!,
              style: TextStyle(color: _ok ? Cores.verde : Cores.erro),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _testando ? null : _testar,
          child: Text(_testando ? 'Testando...' : 'Testar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () async {
            if (!_urlValida()) return;
            await context.read<ArmazenamentoLocal>().salvarUrlApi(_url.text);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
