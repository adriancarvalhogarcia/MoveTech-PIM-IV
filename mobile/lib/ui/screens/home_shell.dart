import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/sync_service.dart';
import 'clientes_screen.dart';
import 'inicio_screen.dart';
import 'nova_venda_screen.dart';
import 'produtos_screen.dart';
import 'vendas_screen.dart';

/// Estrutura principal após o login: navegação inferior com 5 abas.
///
/// Fluxo de navegação:
///   Login -> [Início | Produtos | Nova venda | Clientes | Vendas]
///   Início -> Minha conta
///   Produtos -> Detalhe do produto
///   Clientes -> Formulário (novo / editar)
///   Vendas -> Detalhe da venda
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const abaInicio = 0;
  static const abaProdutos = 1;
  static const abaNovaVenda = 2;
  static const abaClientes = 3;
  static const abaVendas = 4;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _aba = HomeShell.abaInicio;
  late final SyncService _sync;

  @override
  void initState() {
    super.initState();
    _sync = context.read<SyncService>();
    WidgetsBinding.instance.addObserver(this);
    // Envia vendas que ficaram pendentes de uma sessão anterior.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync.sincronizar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sync.pararAgendamento();
    super.dispose();
  }

  /// Ao voltar para o app (ex.: depois de recuperar o sinal), sincroniza.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync.sincronizar();
    }
  }

  void _irPara(int aba) => setState(() => _aba = aba);

  @override
  Widget build(BuildContext context) {
    final pendentes = context.select<SyncService, int>(
      (s) => s.totalAguardando + s.totalRejeitadas,
    );

    return Scaffold(
      body: IndexedStack(
        index: _aba,
        children: [
          InicioScreen(aoIrPara: _irPara),
          const ProdutosScreen(),
          NovaVendaScreen(aoConcluir: () => _irPara(HomeShell.abaVendas)),
          const ClientesScreen(),
          const VendasScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: _irPara,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chair_outlined),
            selectedIcon: Icon(Icons.chair_rounded),
            label: 'Produtos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_shopping_cart_outlined),
            selectedIcon: Icon(Icons.add_shopping_cart_rounded),
            label: 'Nova venda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendentes > 0,
              label: Text('$pendentes'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendentes > 0,
              label: Text('$pendentes'),
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'Vendas',
            tooltip: pendentes > 0
                ? 'Vendas, $pendentes aguardando sincronização'
                : 'Vendas',
          ),
        ],
      ),
    );
  }
}
