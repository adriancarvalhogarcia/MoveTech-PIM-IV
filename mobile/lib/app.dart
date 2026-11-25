import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/login_screen.dart';

class MoveTechApp extends StatefulWidget {
  const MoveTechApp({super.key});

  @override
  State<MoveTechApp> createState() => _MoveTechAppState();
}

class _MoveTechAppState extends State<MoveTechApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _auth.addListener(_aoMudarSessao);
  }

  /// Se a sessão terminar (logout ou token expirado) com alguma tela
  /// empilhada por cima (ex.: formulário de cliente), fecha todas.
  void _aoMudarSessao() {
    if (_auth.estado == EstadoSessao.desconectado) {
      _navigatorKey.currentState?.popUntil((rota) => rota.isFirst);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_aoMudarSessao);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.nomeApp,
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.escuro,
      home: const _PortaoAutenticacao(),
    );
  }
}

/// Decide qual tela mostrar conforme o estado da sessão.
class _PortaoAutenticacao extends StatelessWidget {
  const _PortaoAutenticacao();

  @override
  Widget build(BuildContext context) {
    final estado = context.select<AuthService, EstadoSessao>((a) => a.estado);

    switch (estado) {
      case EstadoSessao.verificando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case EstadoSessao.desconectado:
        return const LoginScreen();
      case EstadoSessao.conectado:
        return const HomeShell();
    }
  }
}
