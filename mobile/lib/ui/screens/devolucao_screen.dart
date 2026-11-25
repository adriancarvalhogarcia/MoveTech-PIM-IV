import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../core/utils/pagamento.dart';
import '../../data/models/venda.dart';
import '../../data/repositories/venda_repository.dart';
import '../widgets/componentes.dart';

/// Devolução total ou parcial de uma venda (POST /api/vendas/{id}/devolucoes).
///
/// O servidor devolve os produtos ao estoque, abate as parcelas em aberto
/// e, se o cliente já tinha pago, gera um reembolso (conta a pagar).
/// Precisa de conexão: a devolução não entra na fila offline.
class DevolucaoScreen extends StatefulWidget {
  const DevolucaoScreen({super.key, required this.venda});

  final Venda venda;

  @override
  State<DevolucaoScreen> createState() => _DevolucaoScreenState();
}

class _DevolucaoScreenState extends State<DevolucaoScreen> {
  final _form = GlobalKey<FormState>();
  final _motivo = TextEditingController();

  /// itemVendaId -> quantidade a devolver
  final Map<int, int> _quantidades = {};
  String? _formaReembolso;
  bool _enviando = false;

  List<ItemVenda> get _itens => widget.venda.itens.where((i) => i.id != null).toList();

  double get _total => _itens.fold(
        0.0,
        (soma, i) => soma + (_quantidades[i.id] ?? 0) * i.precoUnitario,
      );

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _alterar(ItemVenda item, int delta) {
    final atual = _quantidades[item.id!] ?? 0;
    final novo = (atual + delta).clamp(0, item.disponivelParaDevolver).toInt();
    setState(() => _quantidades[item.id!] = novo);
  }

  void _tudo() {
    setState(() {
      for (final i in _itens) {
        _quantidades[i.id!] = i.disponivelParaDevolver;
      }
    });
  }

  Future<void> _confirmar() async {
    if (_enviando) return;
    if (!_form.currentState!.validate()) return;

    final itens = {
      for (final e in _quantidades.entries)
        if (e.value > 0) e.key: e.value,
    };

    if (itens.isEmpty) {
      mostrarMensagem(context, 'Informe a quantidade de pelo menos um item.', erro: true);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar devolução'),
        content: Text(
          'Venda #${widget.venda.id} · ${widget.venda.clienteNome}\n'
          'Valor devolvido: ${Formatadores.moeda(_total)}\n\n'
          'Os produtos voltam ao estoque e o financeiro é ajustado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _enviando = true);

    try {
      final r = await context.read<VendaRepository>().devolver(
            widget.venda.id,
            motivo: _motivo.text,
            itens: itens,
            formaReembolso: _formaReembolso,
          );

      if (!mounted) return;

      var texto = r['mensagem']?.toString() ?? 'Devolução registrada.';
      final reembolso = r['reembolso'];
      if (reembolso is Map) {
        final valor = Formatadores.moeda(Formatadores.lerDecimal(reembolso['valor']));
        texto += reembolso['pago'] == true
            ? ' Reembolso de $valor registrado como pago.'
            : ' Reembolso de $valor lançado em aberto no Financeiro.';
      }

      mostrarMensagem(context, texto);
      Navigator.pop(context, true);
    } on SemConexaoException catch (e) {
      if (mounted) {
        mostrarMensagem(context, '${e.mensagem} A devolução precisa de conexão com o servidor.',
            erro: true);
      }
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Devolução · venda #${widget.venda.id}'),
        actions: [
          TextButton(onPressed: _tudo, child: const Text('Devolver tudo')),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Cores.superficie,
            border: Border(top: BorderSide(color: Cores.borda)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Total a devolver: ${Formatadores.moeda(_total)}',
                  excludeSemantics: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('A devolver', style: TextStyle(color: Cores.textoSecundario)),
                      Text(
                        Formatadores.moeda(_total),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: FilledButton(
                  onPressed: _enviando || _total <= 0 ? null : _confirmar,
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Escolha quanto de cada item volta para a loja.',
                style: TextStyle(color: Cores.textoSecundario),
              ),
            ),
            const TituloSecao('Itens'),
            for (final item in _itens)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.produtoNome,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                item.disponivelParaDevolver == 0
                                    ? 'Já devolvido por completo'
                                    : 'Vendido ${item.quantidade} · pode devolver '
                                        '${item.disponivelParaDevolver} · '
                                        '${Formatadores.moeda(item.precoUnitario)} cada',
                                style: const TextStyle(
                                    color: Cores.textoSecundario, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Diminuir quantidade de ${item.produtoNome}',
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          onPressed: (_quantidades[item.id] ?? 0) == 0
                              ? null
                              : () => _alterar(item, -1),
                        ),
                        Semantics(
                          label: 'Devolver ${_quantidades[item.id] ?? 0}',
                          excludeSemantics: true,
                          child: Text(
                            '${_quantidades[item.id] ?? 0}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Aumentar quantidade de ${item.produtoNome}',
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          onPressed: (_quantidades[item.id] ?? 0) >= item.disponivelParaDevolver
                              ? null
                              : () => _alterar(item, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const TituloSecao('Motivo'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _motivo,
                maxLength: 250,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Motivo da devolução',
                  hintText: 'Ex.: produto com avaria, cliente desistiu',
                ),
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Descreva o motivo (mínimo de 3 caracteres).'
                    : null,
              ),
            ),
            const TituloSecao('Reembolso'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String?>(
                value: _formaReembolso,
                decoration: const InputDecoration(
                  labelText: 'Se o cliente já pagou',
                  helperText: 'Parcelas em aberto são abatidas automaticamente.',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Deixar em aberto no Financeiro')),
                  for (final f in FormasPagamento.baixa)
                    DropdownMenuItem(value: f, child: Text('Já devolvi: ${FormasPagamento.nome(f)}')),
                ],
                onChanged: (v) => setState(() => _formaReembolso = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
