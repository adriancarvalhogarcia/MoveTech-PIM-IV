import '../../core/network/api_client.dart';
import '../../core/utils/formatadores.dart';
import '../models/conta_financeira.dart';

/// Financeiro (somente administrador): /api/financeiro.
class FinanceiroRepository {
  FinanceiroRepository(this._api);

  final ApiClient _api;

  Future<ResumoFinanceiro> resumo() async {
    final r = await _api.get('/financeiro/resumo');
    return ResumoFinanceiro.fromJson(Map<String, dynamic>.from(r as Map));
  }

  /// [status]: Aberta, Vencida, Paga, Cancelada ou null (todas).
  Future<List<ContaFinanceira>> listar({String? tipo, String? status, String? busca, int? vendaId}) async {
    final parametros = <String, String>{
      if (tipo != null) 'tipo': tipo,
      if (status != null) 'status': status,
      if (busca != null && busca.trim().isNotEmpty) 'busca': busca.trim(),
      if (vendaId != null) 'vendaId': '$vendaId',
    };
    final consulta = parametros.isEmpty
        ? ''
        : '?${parametros.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final r = await _api.get('/financeiro$consulta') as List;
    return r
        .whereType<Map>()
        .map((e) => ContaFinanceira.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<HistoricoConta>> historico(int id) async {
    final r = Map<String, dynamic>.from(await _api.get('/financeiro/$id') as Map);
    return (r['historico'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => HistoricoConta.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> baixar(
    int id, {
    required String formaPagamento,
    required DateTime data,
    required double valorPago,
    String? observacao,
  }) async {
    final r = await _api.post('/financeiro/$id/baixar', corpo: {
      'formaPagamento': formaPagamento,
      'dataPagamento': Formatadores.isoData(data),
      'valorPago': double.parse(valorPago.toStringAsFixed(2)),
      if (observacao != null && observacao.trim().isNotEmpty) 'observacao': observacao.trim(),
    });
    return (r as Map)['mensagem']?.toString() ?? 'Baixa registrada.';
  }

  Future<String> estornar(int id, String motivo) async {
    final r = await _api.post('/financeiro/$id/estornar', corpo: {'motivo': motivo.trim()});
    return (r as Map)['mensagem']?.toString() ?? 'Baixa estornada.';
  }

  Future<String> cancelar(int id, String motivo) async {
    final r = await _api.post('/financeiro/$id/cancelar', corpo: {'motivo': motivo.trim()});
    return (r as Map)['mensagem']?.toString() ?? 'Conta cancelada.';
  }

  Future<String> lancar({
    required String tipo,
    required String descricao,
    required double valor,
    required DateTime vencimento,
    int parcelas = 1,
    String? observacao,
  }) async {
    final r = await _api.post('/financeiro', corpo: {
      'tipo': tipo,
      'descricao': descricao.trim(),
      'valor': double.parse(valor.toStringAsFixed(2)),
      'vencimento': Formatadores.isoData(vencimento),
      'parcelas': parcelas,
      if (observacao != null && observacao.trim().isNotEmpty) 'observacao': observacao.trim(),
    });
    return (r as Map)['mensagem']?.toString() ?? 'Conta lançada.';
  }
}
