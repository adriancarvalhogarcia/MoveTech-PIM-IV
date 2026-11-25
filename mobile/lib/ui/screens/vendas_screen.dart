import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../core/utils/pagamento.dart';
import '../../data/models/venda.dart';
import '../../data/models/venda_pendente.dart';
import '../../data/repositories/dados_carregados.dart';
import '../../data/repositories/venda_repository.dart';
import '../../services/sync_service.dart';
import '../widgets/componentes.dart';
import '../widgets/recarregar_ao_sincronizar.dart';
import 'devolucao_screen.dart';

/// Histórico de vendas: GET /api/vendas + fila local de vendas offline.
class VendasScreen extends StatefulWidget {
  const VendasScreen({super.key});

  @override
  State<VendasScreen> createState() => _VendasScreenState();
}

class _VendasScreenState extends State<VendasScreen> with RecarregarAoSincronizar {
  final _busca = TextEditingController();
  DadosCarregados<List<Venda>>? _dados;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    recarregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Future<void> recarregar() async {
    setState(() {
      _carregando = _dados == null;
      _erro = null;
    });
    try {
      final dados = await context.read<VendaRepository>().listar();
      if (mounted) setState(() => _dados = dados);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _atualizarTudo() async {
    await context.read<SyncService>().sincronizar();
    await recarregar();
  }

  List<Venda> get _filtradas {
    final termo = _busca.text.trim().toLowerCase();
    final vendas = _dados?.dados ?? const <Venda>[];
    if (termo.isEmpty) return vendas;
    return vendas
        .where((v) =>
            v.clienteNome.toLowerCase().contains(termo) ||
            v.id.toString() == termo.replaceAll('#', ''))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    observarSincronizacao(context);
    final sync = context.watch<SyncService>();
    final fila = sync.fila;

    return Scaffold(
      appBar: AppBar(title: const Text('Vendas')),
      body: Column(
        children: [
          const BannerSincronizacao(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _atualizarTudo,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (fila.isNotEmpty) ...[
                    TituloSecao(
                      'Aguardando sincronização (${fila.length})',
                      acao: TextButton.icon(
                        onPressed: sync.sincronizando ? null : sync.sincronizar,
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('Enviar agora'),
                      ),
                    ),
                    ...fila.map((v) => _CartaoPendente(venda: v)),
                    if (sync.ultimaMensagem != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Text(
                          sync.ultimaMensagem!,
                          style: const TextStyle(
                              color: Cores.textoSecundario, fontSize: 12),
                        ),
                      ),
                  ],
                  const TituloSecao('Vendas registradas no servidor'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CampoBusca(
                      controller: _busca,
                      dica: 'Buscar por cliente ou número',
                      aoMudar: (_) => setState(() {}),
                    ),
                  ),
                  if (_dados?.doCache == true)
                    AvisoCache(atualizadoEm: _dados!.atualizadoEm),
                  ..._historico(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _historico() {
    if (_carregando) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_dados == null) {
      return [EstadoErro(mensagem: _erro ?? 'Erro desconhecido.', aoTentar: recarregar)];
    }
    final vendas = _filtradas;
    if (vendas.isEmpty) {
      return const [
        EstadoVazio(icone: Icons.receipt_long_outlined, titulo: 'Nenhuma venda encontrada'),
      ];
    }
    return vendas
        .map(
          (v) => ListTile(
            leading: CircleAvatar(
              backgroundColor: Cores.verde.withAlpha(40),
              foregroundColor: Cores.verde,
              child: const Icon(Icons.receipt_rounded, size: 20),
            ),
            title: Text(v.clienteNome, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '#${v.id} · ${Formatadores.dataHora(v.criadoEm)} · ${v.quantidadeItens} item(ns)'
              '\n${FormasPagamento.nome(v.formaPagamento)}${v.parcelas > 1 ? ' · ${v.parcelas}x' : ''}',
            ),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatadores.moeda(v.valorTotal),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (v.totalmenteDevolvida)
                  const Selo('Devolvida', cor: Cores.erro)
                else if (v.devolvidaParcial)
                  const Selo('Dev. parcial', cor: Cores.alerta),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VendaDetalheScreen(venda: v)),
            ),
          ),
        )
        .toList();
  }
}

class _CartaoPendente extends StatelessWidget {
  const _CartaoPendente({required this.venda});

  final VendaPendente venda;

  @override
  Widget build(BuildContext context) {
    final sync = context.read<SyncService>();
    final rejeitada = venda.status == StatusPendente.rejeitada;
    final enviando = venda.status == StatusPendente.enviando;
    final cor = rejeitada ? Cores.erro : Cores.alerta;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cor.withAlpha(110)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      venda.clienteNome,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Selo(
                    rejeitada ? 'Recusada' : (enviando ? 'Enviando...' : 'Pendente'),
                    cor: cor,
                    icone: rejeitada ? Icons.error_outline_rounded : Icons.schedule_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${Formatadores.dataHora(venda.criadoEm)} · '
                'Estimado: ${Formatadores.moeda(venda.valorEstimado)}',
                style: const TextStyle(color: Cores.textoSecundario, fontSize: 13),
              ),
              const SizedBox(height: 4),
              ...venda.itens.map(
                (i) => Text(
                  '${i.quantidade}x ${i.produtoNome}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (rejeitada) ...[
                const SizedBox(height: 8),
                Text(
                  'Motivo: ${venda.mensagemErro ?? 'recusada pelo servidor'}',
                  style: const TextStyle(color: Cores.erro, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Descartar venda?'),
                            content: const Text(
                              'A venda recusada será removida do aparelho. '
                              'Esta ação não pode ser desfeita.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Descartar',
                                  style: TextStyle(color: Cores.erro),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await sync.descartar(venda.idLocal);
                      },
                      child: const Text('Descartar'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => sync.tentarNovamente(venda.idLocal),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Detalhe de uma venda já registrada no servidor, com devoluções.
/// Busca a versão atualizada na API (GET /api/vendas/{id}); sem conexão,
/// mostra os dados da lista.
class VendaDetalheScreen extends StatefulWidget {
  const VendaDetalheScreen({super.key, required this.venda});

  final Venda venda;

  @override
  State<VendaDetalheScreen> createState() => _VendaDetalheScreenState();
}

class _VendaDetalheScreenState extends State<VendaDetalheScreen> {
  late Venda _venda = widget.venda;
  bool _atualizando = true;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  Future<void> _atualizar() async {
    setState(() => _atualizando = true);
    try {
      final venda = await context.read<VendaRepository>().buscar(widget.venda.id);
      if (mounted) setState(() => _venda = venda);
    } catch (_) {
      // Mantém os dados da lista (ex.: sem conexão).
    } finally {
      if (mounted) setState(() => _atualizando = false);
    }
  }

  Future<void> _devolver() async {
    final concluiu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DevolucaoScreen(venda: _venda)),
    );
    if (concluiu == true && mounted) {
      context.read<SyncService>().notificarAlteracaoDados();
      await _atualizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final venda = _venda;

    return Scaffold(
      appBar: AppBar(
        title: Text('Venda #${venda.id}'),
        bottom: _atualizando
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      bottomNavigationBar: venda.totalmenteDevolvida
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: OutlinedButton.icon(
                  onPressed: _atualizando ? null : _devolver,
                  icon: const Icon(Icons.assignment_return_rounded),
                  label: const Text('Registrar devolução'),
                ),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: _atualizar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            venda.clienteNome,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (venda.totalmenteDevolvida)
                          const Selo('Devolvida', cor: Cores.erro)
                        else if (venda.devolvidaParcial)
                          const Selo('Devolução parcial', cor: Cores.alerta)
                        else
                          const Selo('Concluída'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Linha('Data', Formatadores.dataHora(venda.criadoEm)),
                    _Linha(
                      'Pagamento',
                      '${FormasPagamento.nome(venda.formaPagamento)}'
                          '${venda.parcelas > 1 ? ' em ${venda.parcelas}x' : ''}',
                    ),
                    if (venda.valorDevolvido > 0)
                      _Linha('Devolvido', Formatadores.moeda(venda.valorDevolvido)),
                  ],
                ),
              ),
            ),
            const TituloSecao('Itens'),
            Card(
              child: Column(
                children: [
                  for (final item in venda.itens) ...[
                    ListTile(
                      title: Text(item.produtoNome),
                      subtitle: Text(
                        '${item.quantidade} x ${Formatadores.moeda(item.precoUnitario)}'
                        '${item.quantidadeDevolvida > 0 ? ' · ${item.quantidadeDevolvida} devolvido(s)' : ''}',
                      ),
                      trailing: Text(Formatadores.moeda(item.subtotal)),
                    ),
                    if (item != venda.itens.last) const Divider(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  Formatadores.moeda(venda.valorTotal),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Cores.verde,
                  ),
                ),
              ],
            ),
            if (venda.valorDevolvido > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Líquido após devoluções: ${Formatadores.moeda(venda.valorLiquido)}',
                  style: const TextStyle(color: Cores.textoSecundario),
                ),
              ),
            if (venda.devolucoes.isNotEmpty) ...[
              const TituloSecao('Devoluções'),
              Card(
                child: Column(
                  children: [
                    for (final d in venda.devolucoes)
                      ListTile(
                        leading: const Icon(Icons.assignment_return_rounded, color: Cores.alerta),
                        title: Text(d.itens),
                        subtitle: Text(
                          '${Formatadores.dataHora(d.criadoEm)} · ${d.motivo}'
                          '${d.usuarioNome != null ? ' · ${d.usuarioNome}' : ''}',
                        ),
                        trailing: Text(Formatadores.moeda(d.valorTotal)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(rotulo, style: const TextStyle(color: Cores.textoSecundario)),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}
