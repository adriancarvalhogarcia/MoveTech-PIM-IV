import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../local/armazenamento_local.dart';
import '../models/dashboard.dart';
import 'dados_carregados.dart';

/// Indicadores: GET /api/relatorios/dashboard.
class DashboardRepository {
  DashboardRepository(this._api, this._local);

  final ApiClient _api;
  final ArmazenamentoLocal _local;

  Future<DadosCarregados<Dashboard>> carregar() async {
    try {
      final resposta = await _api.get('/relatorios/dashboard');
      final json = Map<String, dynamic>.from(resposta as Map);
      await _local.salvarCache(ChavesArmazenamento.cacheDashboard, json);
      return DadosCarregados(Dashboard.fromJson(json));
    } on SemConexaoException {
      final registro = _local.lerCache(ChavesArmazenamento.cacheDashboard);
      if (registro == null || registro.dados is! Map) rethrow;
      return DadosCarregados(
        Dashboard.fromJson(Map<String, dynamic>.from(registro.dados as Map)),
        doCache: true,
        atualizadoEm: registro.atualizadoEm,
      );
    }
  }
}
