import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../local/armazenamento_local.dart';
import '../models/venda.dart';
import 'dados_carregados.dart';

/// Vendas: GET /api/vendas, GET /api/vendas/{id}, POST /api/vendas e devoluções.
class VendaRepository {
  VendaRepository(this._api, this._local);

  final ApiClient _api;
  final ArmazenamentoLocal _local;

  Future<DadosCarregados<List<Venda>>> listar() async {
    try {
      final resposta = await _api.get('/vendas') as List;
      final vendas = _converter(resposta);
      await _local.salvarCache(
        ChavesArmazenamento.cacheVendas,
        vendas.map((v) => v.toJson()).toList(),
      );
      return DadosCarregados(vendas);
    } on SemConexaoException {
      final registro = _local.lerCache(ChavesArmazenamento.cacheVendas);
      if (registro == null || registro.dados is! List) rethrow;
      return DadosCarregados(
        _converter(registro.dados as List),
        doCache: true,
        atualizadoEm: registro.atualizadoEm,
      );
    }
  }

  Future<Venda> buscar(int id) async {
    final resposta = await _api.get('/vendas/$id');
    return Venda.fromJson(Map<String, dynamic>.from(resposta as Map));
  }

  /// Envia a venda. A API confere cliente ativo, produtos ativos e
  /// estoque, calcula os valores e baixa o estoque no banco.
  ///
  /// Lança [SemConexaoException] se o servidor não responder e
  /// [ApiException] se a venda for recusada (ex.: estoque insuficiente).
  Future<Venda> registrar(Map<String, dynamic> corpo) async {
    final resposta = await _api.post('/vendas', corpo: corpo);
    return Venda.fromJson(Map<String, dynamic>.from(resposta as Map));
  }

  /// Devolução total ou parcial: POST /api/vendas/{id}/devolucoes.
  /// [itens]: itemVendaId -> quantidade a devolver.
  Future<Map<String, dynamic>> devolver(
    int vendaId, {
    required String motivo,
    required Map<int, int> itens,
    String? formaReembolso,
  }) async {
    final r = await _api.post('/vendas/$vendaId/devolucoes', corpo: {
      'motivo': motivo.trim(),
      'itens': itens.entries
          .where((e) => e.value > 0)
          .map((e) => {'itemVendaId': e.key, 'quantidade': e.value})
          .toList(),
      if (formaReembolso != null) 'formaReembolso': formaReembolso,
    });
    return Map<String, dynamic>.from(r as Map);
  }

  List<Venda> _converter(List lista) => lista
      .whereType<Map>()
      .map((e) => Venda.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
