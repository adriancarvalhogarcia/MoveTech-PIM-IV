import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../data/models/usuario.dart';
import '../data/repositories/auth_repository.dart';

enum EstadoSessao { verificando, desconectado, conectado }

/// Estado de autenticação do aplicativo (camada de serviço).
///
/// As telas observam esta classe: quando o estado muda para
/// [EstadoSessao.desconectado], o app volta automaticamente ao login.
class AuthService extends ChangeNotifier {
  AuthService(this._repositorio, ApiClient api) {
    // Token expirado ou inválido em qualquer requisição -> volta ao login.
    api.aoExpirarSessao = () {
      if (_estado == EstadoSessao.conectado) {
        sair(motivo: 'Sua sessão expirou. Entre novamente.');
      }
    };
  }

  final AuthRepository _repositorio;

  EstadoSessao _estado = EstadoSessao.verificando;
  Usuario? _usuario;
  String? _aviso;

  EstadoSessao get estado => _estado;
  Usuario? get usuario => _usuario;

  /// Mensagem exibida na tela de login (ex.: sessão expirada).
  String? get aviso => _aviso;

  Future<void> iniciar() async {
    _usuario = await _repositorio.restaurarSessao();
    _estado =
        _usuario == null ? EstadoSessao.desconectado : EstadoSessao.conectado;
    notifyListeners();
  }

  /// Lança ApiException (credenciais inválidas, usuário inativo)
  /// ou SemConexaoException para a tela tratar.
  Future<void> entrar(String email, String senha) async {
    _usuario = await _repositorio.login(email, senha);
    _aviso = null;
    _estado = EstadoSessao.conectado;
    notifyListeners();
  }

  Future<void> sair({String? motivo}) async {
    await _repositorio.logout();
    _usuario = null;
    _aviso = motivo;
    _estado = EstadoSessao.desconectado;
    notifyListeners();
  }

  void limparAviso() {
    _aviso = null;
  }
}
