import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../core/utils/validadores.dart';
import '../../data/models/produto.dart';
import '../../data/repositories/produto_repository.dart';
import '../../services/sync_service.dart';
import '../widgets/componentes.dart';

/// Cadastro (POST /api/produtos) e edição (PUT /api/produtos/{id}).
class ProdutoFormScreen extends StatefulWidget {
  const ProdutoFormScreen({super.key, this.produto});

  /// null = novo produto.
  final Produto? produto;

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late final TextEditingController _categoria;
  late final TextEditingController _preco;
  late final TextEditingController _estoque;
  late final TextEditingController _minimo;
  late bool _ativo;
  bool _salvando = false;
  bool _tentouSalvar = false;
  String? _erro;
  List<String> _categorias = const [];

  bool get _edicao => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    _nome = TextEditingController(text: p?.nome ?? '');
    _descricao = TextEditingController(text: p?.descricao ?? '');
    _categoria = TextEditingController(text: p?.categoria ?? '');
    _preco = TextEditingController(
      text: p == null ? '' : _MascaraMoeda.formatar((p.preco * 100).round()),
    );
    _estoque = TextEditingController(text: p == null ? '0' : '${p.quantidadeEstoque}');
    _minimo = TextEditingController(text: p == null ? '0' : '${p.estoqueMinimo}');
    _ativo = p?.ativo ?? true;
    _categorias = context.read<ProdutoRepository>().categoriasNoCache();
  }

  @override
  void dispose() {
    for (final c in [_nome, _descricao, _categoria, _preco, _estoque, _minimo]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _precoDigitado {
    final d = Formatadores.somenteDigitos(_preco.text);
    if (d.isEmpty) return null;
    return int.parse(d) / 100;
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    if (_salvando) return; // evita envio duplicado por toque duplo
    if (!_form.currentState!.validate()) {
      setState(() => _tentouSalvar = true);
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final repo = context.read<ProdutoRepository>();
    final sync = context.read<SyncService>();
    try {
      final preco = _precoDigitado!;
      final estoque = int.parse(_estoque.text.trim());
      final minimo = int.parse(_minimo.text.trim());
      if (_edicao) {
        await repo.atualizar(
          widget.produto!.id,
          nome: _nome.text,
          descricao: _descricao.text,
          categoria: _categoria.text,
          preco: preco,
          quantidadeEstoque: estoque,
          estoqueMinimo: minimo,
          ativo: _ativo,
        );
      } else {
        await repo.criar(
          nome: _nome.text,
          descricao: _descricao.text,
          categoria: _categoria.text,
          preco: preco,
          quantidadeEstoque: estoque,
          estoqueMinimo: minimo,
        );
      }
      // Produtos, Nova venda e Início recarregam na hora.
      sync.notificarAlteracaoDados();
      if (!mounted) return;
      mostrarMensagem(context, _edicao ? 'Produto atualizado.' : 'Produto cadastrado.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } on SemConexaoException catch (e) {
      setState(() => _erro = '${e.mensagem}\nO produto não foi salvo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edicao ? 'Editar produto' : 'Novo produto')),
      body: SafeArea(
        child: Form(
          key: _form,
          autovalidateMode: _tentouSalvar
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nome,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: const InputDecoration(labelText: 'Nome do produto *'),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Informe o nome.';
                  if (t.length < 3) return 'O nome deve ter pelo menos 3 caracteres.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _categoria,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                  hintText: 'Ex.: Sala, Quarto, Cozinha',
                ),
                validator: (v) =>
                    Validadores.obrigatorio(v, campo: 'A categoria'),
              ),
              if (_categorias.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _categorias
                      .map(
                        (c) => ActionChip(
                          label: Text(c),
                          onPressed: () => setState(() => _categoria.text = c),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _preco,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  _MascaraMoeda(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Preço de venda *',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
                validator: (_) => Validadores.preco(_precoDigitado),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _estoque,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(labelText: 'Estoque atual *'),
                      validator: (v) =>
                          Validadores.inteiroNaoNegativo(v, campo: 'O estoque'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minimo,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(labelText: 'Estoque mínimo *'),
                      validator: (v) =>
                          Validadores.inteiroNaoNegativo(v, campo: 'O estoque mínimo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Abaixo do estoque mínimo o produto aparece como "estoque baixo".',
                style: TextStyle(color: Cores.textoSecundario, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descricao,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              if (_edicao) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Produto ativo'),
                  subtitle: const Text(
                    'Produtos inativos não aparecem para novas vendas.',
                    style: TextStyle(color: Cores.textoSecundario),
                  ),
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                ),
              ],
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(_erro!, style: const TextStyle(color: Cores.erro)),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_edicao ? 'Salvar alterações' : 'Cadastrar produto'),
              ),
              const SizedBox(height: 8),
              const Text(
                '* Campos obrigatórios',
                style: TextStyle(color: Cores.textoSecundario, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Máscara de valor em reais enquanto o usuário digita:
/// 1 -> 0,01 · 1500 -> 15,00 · 123456 -> 1.234,56
class _MascaraMoeda extends TextInputFormatter {
  static String formatar(int centavos) {
    final texto = Formatadores.moeda(centavos / 100);
    return texto.replaceFirst('R\$ ', '');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = Formatadores.somenteDigitos(newValue.text);
    if (digitos.isEmpty) return const TextEditingValue(text: '');
    final texto = formatar(int.parse(digitos));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Diálogo de entrada de estoque. Devolve a quantidade a somar ou null.
Future<int?> pedirQuantidadeEntrada(BuildContext context, Produto produto) {
  return showDialog<int>(
    context: context,
    builder: (_) => _DialogoEntrada(produto: produto),
  );
}

class _DialogoEntrada extends StatefulWidget {
  const _DialogoEntrada({required this.produto});

  final Produto produto;

  @override
  State<_DialogoEntrada> createState() => _DialogoEntradaState();
}

class _DialogoEntradaState extends State<_DialogoEntrada> {
  final _form = GlobalKey<FormState>();
  final _quantidade = TextEditingController();

  @override
  void dispose() {
    _quantidade.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, int.parse(_quantidade.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final digitado = int.tryParse(_quantidade.text.trim()) ?? 0;
    return AlertDialog(
      title: const Text('Entrada de estoque'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Estoque atual: ${p.quantidadeEstoque} unidade(s)',
              style: const TextStyle(color: Cores.textoSecundario),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _quantidade,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              decoration: const InputDecoration(labelText: 'Quantidade recebida'),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _confirmar(),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1) return 'Informe pelo menos 1 unidade.';
                if (n > 99999) return 'Máximo de 99999 por entrada.';
                return null;
              },
            ),
            if (digitado > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Novo estoque: ${p.quantidadeEstoque + digitado} unidade(s)',
                style: const TextStyle(color: Cores.verde, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: _confirmar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
