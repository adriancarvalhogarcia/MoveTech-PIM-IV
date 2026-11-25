import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../data/models/nota_entrada.dart';
import '../../data/models/produto.dart';
import '../../data/repositories/nota_entrada_repository.dart';
import '../../data/repositories/produto_repository.dart';
import '../../services/sync_service.dart';
import '../widgets/componentes.dart';

/// Notas de entrada (somente administrador): lista e importação do XML.
class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  List<NotaEntradaResumo>? _notas;
  String? _erro;
  bool _lendo = false;

  static const _tamanhoMaximo = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final notas = await context.read<NotaEntradaRepository>().listar();
      if (mounted) setState(() => _notas = notas);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    }
  }

  Future<void> _importar() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xml'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty || !mounted) return;

    final arquivo = resultado.files.first;

    if (!arquivo.name.toLowerCase().endsWith('.xml')) {
      mostrarMensagem(context, 'Escolha um arquivo .xml da NF-e.', erro: true);
      return;
    }
    if (arquivo.size > _tamanhoMaximo) {
      mostrarMensagem(context, 'O arquivo passa de 5 MB. Confira se é o XML da nota.', erro: true);
      return;
    }
    final bytes = arquivo.bytes;
    if (bytes == null) {
      mostrarMensagem(context, 'Não foi possível ler o arquivo.', erro: true);
      return;
    }

    final xml = utf8.decode(bytes, allowMalformed: true);

    setState(() => _lendo = true);
    try {
      final previa = await context.read<NotaEntradaRepository>().previa(xml, 80);
      if (!mounted) return;

      if (previa.jaImportada) {
        mostrarMensagem(context, 'A nota ${previa.numero} já foi lançada. Não é possível importar de novo.',
            erro: true);
        return;
      }

      final lancou = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PreviaNotaScreen(xml: xml, previa: previa)),
      );
      if (lancou == true) {
        if (mounted) context.read<SyncService>().notificarAlteracaoDados();
        _carregar();
      }
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } on SemConexaoException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _lendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notas de entrada')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _lendo ? null : _importar,
        icon: _lendo
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
            : const Icon(Icons.upload_file_rounded),
        label: Text(_lendo ? 'Lendo nota...' : 'Importar XML'),
      ),
      body: _notas == null
          ? (_erro != null
              ? EstadoErro(mensagem: _erro!, aoTentar: _carregar)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: _carregar,
              child: _notas!.isEmpty
                  ? ListView(children: const [
                      EstadoVazio(
                        icone: Icons.description_outlined,
                        titulo: 'Nenhuma nota lançada',
                        mensagem: 'Toque em “Importar XML” e escolha o arquivo da NF-e do fornecedor.',
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: _notas!.length,
                      itemBuilder: (_, i) {
                        final n = _notas![i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Cores.verde.withAlpha(40),
                            foregroundColor: Cores.verde,
                            child: const Icon(Icons.description_rounded, size: 20),
                          ),
                          title: Text('NF ${n.numero} · ${n.fornecedor}',
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            'Emissão ${Formatadores.dataSimples(n.dataEmissao)} · '
                            '${n.quantidadeItens} item(ns)\n'
                            'Lançada ${Formatadores.dataHora(n.criadoEm)}',
                          ),
                          isThreeLine: true,
                          trailing: Text(Formatadores.moeda(n.valorTotal),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        );
                      },
                    ),
            ),
    );
  }
}

// =================================================================
// PRÉVIA E CONFIRMAÇÃO
// =================================================================

class PreviaNotaScreen extends StatefulWidget {
  const PreviaNotaScreen({super.key, required this.xml, required this.previa});

  final String xml;
  final PreviaNota previa;

  @override
  State<PreviaNotaScreen> createState() => _PreviaNotaScreenState();
}

class _PreviaNotaScreenState extends State<PreviaNotaScreen> {
  final _markup = TextEditingController(text: '80');
  List<Produto> _produtos = [];
  int _parcelas = 1;
  late DateTime _vencimento =
      (widget.previa.dataEmissao ?? DateTime.now()).add(const Duration(days: 30));
  bool _enviando = false;

  PreviaNota get p => widget.previa;

  @override
  void initState() {
    super.initState();
    context.read<ProdutoRepository>().listar().then((r) {
      if (mounted) {
        setState(() => _produtos = [...r.dados]..sort((a, b) => a.nome.compareTo(b.nome)));
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _markup.dispose();
    super.dispose();
  }

  double get _markupAtual => double.tryParse(_markup.text.replaceAll(',', '.')) ?? 0;

  void _recalcularPrecos() {
    setState(() {
      for (final item in p.itens) {
        if (!item.precoEditado) {
          final preco = item.custoUnitario * (1 + _markupAtual / 100);
          item.precoVenda = preco < 0.01 ? 0.01 : double.parse(preco.toStringAsFixed(2));
        }
      }
    });
  }

  String? _validar() {
    if (_markupAtual < 0 || _markupAtual > 1000) return 'O markup deve estar entre 0% e 1000%.';
    for (final item in p.itens) {
      if (!item.quantidadeInteira) {
        return 'Item ${item.numeroItem} tem quantidade fracionada; o estoque usa unidades inteiras.';
      }
      if (item.acao == 'vincular' && item.produtoId == null) {
        return 'Item ${item.numeroItem}: escolha o produto que recebe a entrada.';
      }
      if (item.acao == 'criar') {
        if (item.nome.trim().length < 2) return 'Item ${item.numeroItem}: informe o nome.';
        if (item.precoVenda <= 0) return 'Item ${item.numeroItem}: preço de venda inválido.';
      }
    }
    return null;
  }

  Future<void> _confirmar() async {
    final erro = _validar();
    if (erro != null) {
      mostrarMensagem(context, erro, erro: true);
      return;
    }

    final abaixoDoCusto = p.itens.where((i) => i.acao == 'criar' && i.precoVenda < i.custoUnitario);
    if (abaixoDoCusto.isNotEmpty) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Preço abaixo do custo'),
          content: Text('${abaixoDoCusto.map((i) => i.nome).join(', ')} '
              'ficará com preço de venda menor que o custo. Continuar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Revisar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
          ],
        ),
      );
      if (seguir != true) return;
    }

    if (!mounted) return;
    setState(() => _enviando = true);
    try {
      final msg = await context.read<NotaEntradaRepository>().confirmar(
            xml: widget.xml,
            markup: _markupAtual,
            itens: p.itens,
            parcelas: _parcelas,
            primeiroVencimento: p.duplicatas.isEmpty ? _vencimento : null,
          );
      if (!mounted) return;
      mostrarMensagem(context, msg);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } on SemConexaoException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NF ${p.numero} / ${p.serie}')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _enviando ? null : _confirmar,
            icon: _enviando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.check_rounded),
            label: const Text('Confirmar entrada'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fornecedorNome,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      '${Formatadores.documento(p.fornecedorDocumento)}'
                      '${p.fornecedorCadastrado ? '' : ' · será cadastrado'}',
                      style: const TextStyle(color: Cores.textoSecundario),
                    ),
                    const SizedBox(height: 8),
                    Text('Emissão ${Formatadores.dataSimples(p.dataEmissao)} · '
                        'Total ${Formatadores.moeda(p.valorTotal)}'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _markup,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                labelText: 'Markup para produtos novos (%)',
                helperText: 'Preço sugerido = custo × (1 + markup).',
              ),
              onChanged: (_) => _recalcularPrecos(),
            ),
          ),
          const TituloSecao('Itens da nota'),
          for (final item in p.itens) _cartaoItem(item),
          const TituloSecao('Contas a pagar'),
          if (p.duplicatas.isNotEmpty)
            for (final d in p.duplicatas)
              ListTile(
                dense: true,
                leading: const Icon(Icons.event_note_rounded),
                title: Text('Duplicata ${d.numero}'),
                subtitle: Text('Vence ${Formatadores.dataSimples(d.vencimento)}'),
                trailing: Text(Formatadores.moeda(d.valor)),
              )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('A nota não traz duplicatas. Informe como será pago:',
                      style: TextStyle(color: Cores.textoSecundario)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _parcelas,
                    decoration: const InputDecoration(labelText: 'Parcelas'),
                    items: [for (var n = 1; n <= 24; n++) DropdownMenuItem(value: n, child: Text('${n}x'))],
                    onChanged: (v) => setState(() => _parcelas = v ?? 1),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _vencimento,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        helpText: 'Primeiro vencimento',
                      );
                      if (d != null) setState(() => _vencimento = d);
                    },
                    icon: const Icon(Icons.event_rounded),
                    label: Text('1º vencimento: ${Formatadores.dataSimples(_vencimento)}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cartaoItem(ItemPreviaNota item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.numeroItem}. ${item.descricao}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                '${Formatadores.lerDecimal(item.quantidade).toStringAsFixed(item.quantidadeInteira ? 0 : 3)}'
                ' ${item.unidade ?? ''} · custo ${Formatadores.moeda(item.custoUnitario)} cada',
                style: const TextStyle(color: Cores.textoSecundario, fontSize: 13),
              ),
              if (item.motivoSugestao != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Selo('Reconhecido pelo ${item.motivoSugestao}', icone: Icons.link_rounded),
                ),
              if (!item.quantidadeInteira)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Selo('Quantidade fracionada', cor: Cores.erro),
                ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'vincular', label: Text('Somar a existente')),
                  ButtonSegment(value: 'criar', label: Text('Cadastrar novo')),
                ],
                selected: {item.acao},
                onSelectionChanged: (s) => setState(() => item.acao = s.first),
              ),
              const SizedBox(height: 10),
              if (item.acao == 'vincular')
                DropdownButtonFormField<int>(
                  value: _produtos.any((x) => x.id == item.produtoId) ? item.produtoId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Produto do MoveTech'),
                  items: [
                    for (final prod in _produtos)
                      DropdownMenuItem(
                        value: prod.id,
                        child: Text('${prod.nome} (estoque ${prod.quantidadeEstoque})',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => item.produtoId = v),
                )
              else ...[
                TextFormField(
                  initialValue: item.nome,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Nome do produto'),
                  onChanged: (v) => item.nome = v,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: item.categoria,
                        maxLength: 100,
                        decoration: const InputDecoration(labelText: 'Categoria'),
                        onChanged: (v) => item.categoria = v,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('preco-${item.numeroItem}-${item.precoEditado ? 'm' : item.precoVenda}'),
                        initialValue: item.precoVenda.toStringAsFixed(2).replaceAll('.', ','),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
                        decoration: const InputDecoration(labelText: 'Preço de venda'),
                        onChanged: (v) {
                          item.precoEditado = true;
                          item.precoVenda = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
                Text(
                  item.custoUnitario > 0
                      ? 'Margem: ${((item.precoVenda / item.custoUnitario - 1) * 100).toStringAsFixed(1)}%'
                      : '',
                  style: const TextStyle(color: Cores.textoSecundario, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
