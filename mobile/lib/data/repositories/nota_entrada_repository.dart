import '../../core/network/api_client.dart';
import '../../core/utils/formatadores.dart';
import '../models/nota_entrada.dart';

/// Notas de entrada (somente administrador): /api/notas-entrada.
class NotaEntradaRepository {
  NotaEntradaRepository(this._api);

  final ApiClient _api;

  Future<List<NotaEntradaResumo>> listar() async {
    final r = await _api.get('/notas-entrada') as List;
    return r
        .whereType<Map>()
        .map((e) => NotaEntradaResumo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Lê o XML no servidor e devolve o que será lançado (nada é gravado).
  Future<PreviaNota> previa(String xml, double markup) async {
    final r = await _api.post('/notas-entrada/previa', corpo: {
      'xml': xml,
      'markupPercentual': markup,
    });
    return PreviaNota.fromJson(Map<String, dynamic>.from(r as Map));
  }

  /// Lança a nota: estoque, custo médio, produtos novos e contas a pagar.
  Future<String> confirmar({
    required String xml,
    required double markup,
    required List<ItemPreviaNota> itens,
    int parcelas = 1,
    DateTime? primeiroVencimento,
  }) async {
    final r = await _api.post('/notas-entrada', corpo: {
      'xml': xml,
      'markupPercentual': markup,
      'itens': itens.map((i) => i.decisao()).toList(),
      'parcelas': parcelas,
      if (primeiroVencimento != null) 'primeiroVencimento': Formatadores.isoData(primeiroVencimento),
    });
    return (r as Map)['mensagem']?.toString() ?? 'Nota lançada.';
  }
}
