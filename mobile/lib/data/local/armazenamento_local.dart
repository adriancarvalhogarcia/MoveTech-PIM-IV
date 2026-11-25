import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';

/// Conteúdo lido do cache junto com a data em que foi salvo.
class RegistroCache {
  const RegistroCache(this.dados, this.atualizadoEm);

  final dynamic dados;
  final DateTime? atualizadoEm;
}

/// Camada de persistência local do aplicativo.
///
/// - Token JWT: flutter_secure_storage (Keystore no Android /
///   Keychain no iOS), nunca em texto puro.
/// - Demais dados (usuário, endereço da API, cache e fila offline):
///   shared_preferences em formato JSON.
class ArmazenamentoLocal {
  ArmazenamentoLocal(this._prefs, {FlutterSecureStorage? seguro})
      : _seguro = seguro ?? const FlutterSecureStorage();

  final SharedPreferences _prefs;
  final FlutterSecureStorage _seguro;

  // ---------------------------------------------------------------
  // Token (armazenamento seguro)
  // ---------------------------------------------------------------

  String? _tokenEmMemoria;

  Future<String?> lerToken() async {
    if (_tokenEmMemoria != null) return _tokenEmMemoria;
    try {
      _tokenEmMemoria = await _seguro.read(key: ChavesArmazenamento.token);
    } catch (_) {
      _tokenEmMemoria = null;
    }
    return _tokenEmMemoria;
  }

  Future<void> salvarToken(String token) async {
    _tokenEmMemoria = token;
    await _seguro.write(key: ChavesArmazenamento.token, value: token);
  }

  Future<void> apagarToken() async {
    _tokenEmMemoria = null;
    try {
      await _seguro.delete(key: ChavesArmazenamento.token);
    } catch (_) {
      // Se o armazenamento seguro falhar, o token em memória já foi limpo.
    }
  }

  // ---------------------------------------------------------------
  // Configurações
  // ---------------------------------------------------------------

  String get urlApi =>
      _prefs.getString(ChavesArmazenamento.urlApi) ?? AppConfig.urlApiPadrao;

  Future<void> salvarUrlApi(String url) =>
      _prefs.setString(ChavesArmazenamento.urlApi, url.trim());

  Map<String, dynamic>? lerJson(String chave) {
    final texto = _prefs.getString(chave);
    if (texto == null) return null;
    try {
      final valor = jsonDecode(texto);
      return valor is Map<String, dynamic> ? valor : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarJson(String chave, Map<String, dynamic> valor) =>
      _prefs.setString(chave, jsonEncode(valor));

  Future<void> remover(String chave) => _prefs.remove(chave);

  // ---------------------------------------------------------------
  // Cache com data de atualização
  // ---------------------------------------------------------------

  Future<void> salvarCache(String chave, dynamic dados) => _prefs.setString(
        chave,
        jsonEncode({
          'atualizadoEm': DateTime.now().toUtc().toIso8601String(),
          'dados': dados,
        }),
      );

  RegistroCache? lerCache(String chave) {
    final json = lerJson(chave);
    if (json == null || !json.containsKey('dados')) return null;
    return RegistroCache(
      json['dados'],
      DateTime.tryParse(json['atualizadoEm']?.toString() ?? '')?.toLocal(),
    );
  }

  /// Apaga o cache de dados da empresa (usado no logout).
  /// A fila de vendas pendentes NÃO é apagada aqui, para que nenhuma
  /// venda registrada offline seja perdida.
  Future<void> limparCacheDeDados() async {
    for (final chave in [
      ChavesArmazenamento.cacheProdutos,
      ChavesArmazenamento.cacheClientes,
      ChavesArmazenamento.cacheVendas,
      ChavesArmazenamento.cacheDashboard,
    ]) {
      await _prefs.remove(chave);
    }
  }
}
