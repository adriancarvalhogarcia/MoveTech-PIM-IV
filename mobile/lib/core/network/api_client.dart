import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'conexao_status.dart';

/// Cliente HTTP único do aplicativo.
///
/// Responsabilidades:
/// - montar a URL a partir do endereço configurado da API;
/// - enviar o token JWT no cabeçalho Authorization (Bearer);
/// - converter JSON de/para objetos Dart;
/// - transformar respostas de erro em [ApiException];
/// - transformar falhas de rede em [SemConexaoException];
/// - avisar o app quando o token expirar (HTTP 401).
class ApiClient {
  ApiClient({
    required this.conexao,
    required String Function() obterUrlBase,
    required Future<String?> Function() obterToken,
    http.Client? httpClient,
  })  : _obterUrlBase = obterUrlBase,
        _obterToken = obterToken,
        _http = httpClient ?? http.Client();

  final ConexaoStatus conexao;
  final String Function() _obterUrlBase;
  final Future<String?> Function() _obterToken;
  final http.Client _http;

  /// Chamado quando a API responde 401 em uma rota protegida.
  /// O AuthProvider usa isso para encerrar a sessão.
  void Function()? aoExpirarSessao;

  Future<dynamic> get(String caminho, {bool autenticado = true}) =>
      _enviar('GET', caminho, autenticado: autenticado);

  Future<dynamic> post(String caminho, {Object? corpo, bool autenticado = true}) =>
      _enviar('POST', caminho, corpo: corpo, autenticado: autenticado);

  Future<dynamic> put(String caminho, {Object? corpo}) =>
      _enviar('PUT', caminho, corpo: corpo);

  Future<dynamic> delete(String caminho) => _enviar('DELETE', caminho);

  Uri _montarUri(String caminho) {
    var base = _obterUrlBase().trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final rota = caminho.startsWith('/') ? caminho : '/$caminho';
    return Uri.parse('$base$rota');
  }

  Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    Object? corpo,
    bool autenticado = true,
  }) async {
    final Uri uri;
    try {
      uri = _montarUri(caminho);
    } on FormatException {
      throw SemConexaoException(
        'O endereço da API é inválido. Corrija nas configurações.',
      );
    }

    final cabecalhos = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };

    if (autenticado) {
      final token = await _obterToken();
      if (token != null && token.isNotEmpty) {
        cabecalhos['Authorization'] = 'Bearer $token';
      }
    }

    final requisicao = http.Request(metodo, uri)..headers.addAll(cabecalhos);
    if (corpo != null) {
      requisicao.body = jsonEncode(corpo);
    }

    http.Response resposta;
    try {
      final streamed = await _http
          .send(requisicao)
          .timeout(AppConfig.tempoLimiteRequisicao);
      resposta = await http.Response.fromStream(streamed)
          .timeout(AppConfig.tempoLimiteRequisicao);
    } on TimeoutException {
      conexao.registrarFalha();
      throw SemConexaoException(
        'O servidor demorou para responder. Você está sem conexão?',
      );
    } on http.ClientException {
      conexao.registrarFalha();
      throw SemConexaoException();
    } catch (_) {
      // SocketException, HandshakeException etc.
      conexao.registrarFalha();
      throw SemConexaoException();
    }

    // Qualquer resposta HTTP significa que o servidor está acessível.
    conexao.registrarSucesso();

    final dados = _decodificar(resposta);

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return dados;
    }

    if (resposta.statusCode == 401 && autenticado) {
      aoExpirarSessao?.call();
    }

    throw ApiException(
      resposta.statusCode,
      _extrairMensagem(resposta.statusCode, dados),
      dados: dados is Map<String, dynamic> ? dados : null,
    );
  }

  dynamic _decodificar(http.Response resposta) {
    if (resposta.bodyBytes.isEmpty) return null;
    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);
    try {
      return jsonDecode(texto);
    } on FormatException {
      // A rota "/" da API, por exemplo, devolve texto puro.
      return texto;
    }
  }

  /// A API do MoveTech devolve erros em dois formatos:
  /// 1) { "mensagem": "..." } — erros de regra de negócio;
  /// 2) ProblemDetails do ASP.NET — { "title": "...", "errors": { "Campo": ["..."] } }
  ///    quando a validação dos DTOs ([Required], [MaxLength]...) falha.
  String _extrairMensagem(int status, dynamic dados) {
    if (dados is Map) {
      final mensagem = dados['mensagem'];
      if (mensagem is String && mensagem.isNotEmpty) return mensagem;

      final erros = dados['errors'];
      if (erros is Map && erros.isNotEmpty) {
        final textos = <String>[];
        for (final valor in erros.values) {
          if (valor is List) {
            textos.addAll(valor.map((e) => e.toString()));
          }
        }
        if (textos.isNotEmpty) return textos.join('\n');
      }

      final titulo = dados['title'];
      if (titulo is String && titulo.isNotEmpty) return titulo;
    }

    switch (status) {
      case 400:
        return 'Os dados enviados são inválidos.';
      case 401:
        return 'Sua sessão expirou. Entre novamente.';
      case 403:
        return 'Você não tem permissão para esta ação.';
      case 404:
        return 'Registro não encontrado.';
      case 409:
        return 'Já existe um registro com esses dados.';
      default:
        return 'Erro no servidor (HTTP $status). Tente novamente.';
    }
  }
}
