import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../data/models/dashboard.dart';
import '../../data/repositories/dados_carregados.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../services/auth_service.dart';
import '../widgets/componentes.dart';
import '../widgets/recarregar_ao_sincronizar.dart';
import 'conta_screen.dart';
import 'financeiro_screen.dart';
import 'notas_screen.dart';
import 'home_shell.dart';

/// Resumo do negócio: GET /api/relatorios/dashboard.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, required this.aoIrPara});

  final ValueChanged<int> aoIrPara;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with RecarregarAoSincronizar {
  DadosCarregados<Dashboard>? _dados;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    recarregar();
  }

  @override
  Future<void> recarregar() async {
    setState(() {
      _carregando = _dados == null;
      _erro = null;
    });
    try {
      final dados = await context.read<DashboardRepository>().carregar();
      if (mounted) setState(() => _dados = dados);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _saudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    observarSincronizacao(context);
    final usuario = context.watch<AuthService>().usuario;
    final primeiroNome = (usuario?.nome ?? '').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_saudacao()}, $primeiroNome'),
            Text(
              usuario?.perfilExibicao ?? '',
              style: const TextStyle(fontSize: 13, color: Cores.textoSecundario),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Semantics(
              button: true,
              label: 'Minha conta',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContaScreen()),
                ),
                child: CircleAvatar(
                  backgroundColor: Cores.verde,
                  foregroundColor: Cores.verdeEscuro,
                  child: Text(usuario?.iniciais ?? '?'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const BannerSincronizacao(),
          Expanded(child: _conteudo()),
        ],
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_dados == null) {
      return EstadoErro(mensagem: _erro ?? 'Erro desconhecido.', aoTentar: recarregar);
    }

    final d = _dados!.dados;

    return RefreshIndicator(
      onRefresh: recarregar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_dados!.doCache) AvisoCache(atualizadoEm: _dados!.atualizadoEm),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton.icon(
              onPressed: () => widget.aoIrPara(HomeShell.abaNovaVenda),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Registrar nova venda'),
            ),
          ),
          if (context.read<AuthService>().usuario?.administrador ?? false) ...[
            const TituloSecao('Gestão'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
                      ),
                      icon: const Icon(Icons.account_balance_wallet_rounded),
                      label: const Text('Financeiro'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotasScreen()),
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Notas XML'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const TituloSecao('Indicadores'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                CartaoIndicador(
                  titulo: 'Faturamento total',
                  valor: Formatadores.moeda(d.faturamentoTotal),
                  icone: Icons.payments_rounded,
                ),
                CartaoIndicador(
                  titulo: 'Vendas realizadas',
                  valor: '${d.totalVendas}',
                  icone: Icons.receipt_long_rounded,
                ),
                CartaoIndicador(
                  titulo: 'Ticket médio',
                  valor: Formatadores.moeda(d.ticketMedio),
                  icone: Icons.trending_up_rounded,
                ),
                CartaoIndicador(
                  titulo: 'Clientes ativos',
                  valor: '${d.totalClientesAtivos}',
                  icone: Icons.people_rounded,
                ),
              ],
            ),
          ),
          TituloSecao(
            'Estoque baixo (${d.totalProdutosEstoqueBaixo})',
            acao: TextButton(
              onPressed: () => widget.aoIrPara(HomeShell.abaProdutos),
              child: const Text('Ver produtos'),
            ),
          ),
          if (d.estoqueBaixo.isEmpty)
            const _LinhaInfo('Nenhum produto abaixo do estoque mínimo.')
          else
            ...d.estoqueBaixo.take(5).map(
                  (p) => ListTile(
                    leading: Icon(
                      p.quantidade == 0
                          ? Icons.remove_shopping_cart_rounded
                          : Icons.warning_amber_rounded,
                      color: p.quantidade == 0 ? Cores.erro : Cores.alerta,
                    ),
                    title: Text(p.nome),
                    subtitle: Text('Mínimo: ${p.minimo}'),
                    trailing: Selo(
                      '${p.quantidade} un.',
                      cor: p.quantidade == 0 ? Cores.erro : Cores.alerta,
                    ),
                  ),
                ),
          const TituloSecao('Mais vendidos'),
          if (d.maisVendidos.isEmpty)
            const _LinhaInfo('Ainda não há vendas registradas.')
          else
            ...d.maisVendidos.asMap().entries.map(
                  (e) => ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Cores.superficie2,
                      child: Text('${e.key + 1}º', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(e.value.produto),
                    subtitle: Text('${e.value.quantidade} unidade(s)'),
                    trailing: Text(Formatadores.moeda(e.value.faturamento)),
                  ),
                ),
          TituloSecao(
            'Vendas recentes',
            acao: TextButton(
              onPressed: () => widget.aoIrPara(HomeShell.abaVendas),
              child: const Text('Ver todas'),
            ),
          ),
          if (d.vendasRecentes.isEmpty)
            const _LinhaInfo('Nenhuma venda registrada.')
          else
            ...d.vendasRecentes.map(
              (v) => ListTile(
                leading: const Icon(Icons.receipt_rounded, color: Cores.textoSecundario),
                title: Text(v.cliente),
                subtitle: Text('Venda #${v.id} · ${Formatadores.dataHora(v.data)}'),
                trailing: Text(
                  Formatadores.moeda(v.valor),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(texto, style: const TextStyle(color: Cores.textoSecundario)),
    );
  }
}
