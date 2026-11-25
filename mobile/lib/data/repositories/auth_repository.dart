import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../local/armazenamento_local.dart';
import '../models/usuario.dart';

/// Autenticação com a API: POST /api/auth/login.
class AuthRepository {
  AuthRepository(this._api, this._local);

  final ApiClient _api;
  final ArmazenamentoLocal _local;

  Future<Usuario> login(String email, String senha) async {
    final resposta = await _api.post(
      '/auth/login',
      corpo: {'email': email.trim(), 'senha': senha},
      autenticado: false,
    );

    final mapa = Map<String, dynamic>.from(resposta as Map);
    final token = mapa['token']?.toString() ?? '';
    final usuario =
        Usuario.fromJson(Map<String, dynamic>.from(mapa['usuario'] as Map));

    await _local.salvarToken(token);
    await _local.salvarJson(ChavesArmazenamento.usuario, usuario.toJson());
    return usuario;
  }

  /// Recupera a sessão salva, se o token ainda estiver válido.
  /// Funciona sem internet: permite abrir o app offline e usar o cache.
  Future<Usuario?> restaurarSessao() async {
    final token = await _local.lerToken();
    final usuarioJson = _local.lerJson(ChavesArmazenamento.usuario);
    if (token == null || token.isEmpty || usuarioJson == null) return null;

    final expiracao = expiracaoDoToken(token);
    if (expiracao != null && expiracao.isBefore(DateTime.now())) {
      await logout();
      return null;
    }
    return Usuario.fromJson(usuarioJson);
  }

  Future<void> logout() async {
    await _local.apagarToken();
    await _local.remover(ChavesArmazenamento.usuario);
    await _local.limparCacheDeDados();
  }

  /// Lê a data de expiração ("exp") do payload do JWT.
  /// O token do MoveTech expira 2 horas após o login.
  static DateTime? expiracaoDoToken(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
      final json = jsonDecode(payload);
      final exp = json is Map ? json['exp'] : null;
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      }
    } catch (_) {
      // Token em formato inesperado: deixa a API decidir (401).
    }
    return null;
  }
}
