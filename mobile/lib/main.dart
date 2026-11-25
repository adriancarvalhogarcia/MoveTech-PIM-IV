import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/conexao_status.dart';
import 'data/local/armazenamento_local.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cliente_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/financeiro_repository.dart';
import 'data/repositories/nota_entrada_repository.dart';
import 'data/repositories/produto_repository.dart';
import 'data/repositories/venda_repository.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';

/// Ponto de entrada.
///
/// Aqui as camadas são montadas de baixo para cima (injeção de
/// dependência manual):
///   armazenamento local -> cliente HTTP -> repositórios -> serviços -> telas
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Camada de dados local
  final prefs = await SharedPreferences.getInstance();
  final local = ArmazenamentoLocal(prefs);

  // Camada de rede
  final conexao = ConexaoStatus();
  final api = ApiClient(
    conexao: conexao,
    obterUrlBase: () => local.urlApi,
    obterToken: local.lerToken,
  );

  // Repositórios (acesso à API REST + cache)
  final authRepo = AuthRepository(api, local);
  final produtoRepo = ProdutoRepository(api, local);
  final clienteRepo = ClienteRepository(api, local);
  final vendaRepo = VendaRepository(api, local);
  final dashboardRepo = DashboardRepository(api, local);
  final financeiroRepo = FinanceiroRepository(api);
  final notaRepo = NotaEntradaRepository(api);

  // Serviços (regras do app e estado compartilhado)
  final auth = AuthService(authRepo, api);
  final sync = SyncService(local, vendaRepo, produtoRepo);

  await sync.carregarFila();
  await auth.iniciar();

  runApp(
    MultiProvider(
      providers: [
        Provider<ArmazenamentoLocal>.value(value: local),
        Provider<ApiClient>.value(value: api),
        Provider<ProdutoRepository>.value(value: produtoRepo),
        Provider<ClienteRepository>.value(value: clienteRepo),
        Provider<VendaRepository>.value(value: vendaRepo),
        Provider<DashboardRepository>.value(value: dashboardRepo),
        Provider<FinanceiroRepository>.value(value: financeiroRepo),
        Provider<NotaEntradaRepository>.value(value: notaRepo),
        ChangeNotifierProvider<ConexaoStatus>.value(value: conexao),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<SyncService>.value(value: sync),
      ],
      child: const MoveTechApp(),
    ),
  );
}
