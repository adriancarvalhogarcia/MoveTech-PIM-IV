import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../core/utils/pagamento.dart';
import '../../core/utils/validadores.dart';
import '../../data/models/cliente.dart';
import '../../data/models/produto.dart';
import '../../data/models/venda.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/repositories/produto_repository.dart';
import '../../services/sync_service.dart';
import '../widgets/componentes.dart';
import '../widgets/recarregar_ao_sincronizar.dart';

/// Registro de venda: POST /api/vendas.
///
/// Funciona também sem conexão: nesse caso a venda é guardada no
/// aparelho e enviada automaticamente quando o servidor voltar.
class NovaVendaScreen extends StatefulWidget {
  const NovaVendaScreen({super.key, required this.aoConcluir});

  final VoidCallback aoConcluir;

  @override
  State<NovaVendaScreen> createState() => _NovaVendaScreenState();
}

class _NovaVendaScreenState extends State<NovaVendaScreen>
    with RecarregarAoSincronizar {
  List<Cliente> _clientes = [];
  List<Produto> _produtos = [];
  bool _carregando = true;
  String? _erroCarga;
  bool _usandoCache = false;

  Cliente? _cliente;

  /// Forma de pagamento e parcelas (geram as contas a receber na API).
  String? _forma;
  int _parcelas = 1;

  /// produtoId -> quantidade (mantém a ordem de inclusão).
  final Map<int, int> _carrinho = {};
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    recarregar();
  }

  @override
  Future<void> recarregar() async {
    setState(() {
      _carregando = _produtos.isEmpty && _clientes.isEmpty;
      _erroCarga = null;
    });
    final clienteRepo = context.read<ClienteRepository>();
    final produtoRepo = context.read<ProdutoRepository>();
    try {
      final resultadoClientes = await clienteRepo.listar();
      final resultadoProdutos = await produtoRepo.listar();
      if (!mounted) return;
      setState(() {
        _clientes = resultadoClientes.dados.where((c) => c.ativo).toList();
        _produtos = resultadoProdutos.dados.where((p) => p.ativo).toList();
        _usandoCache = resultadoClientes.doCache || resultadoProdutos.doCache;
        // Ajusta o carrinho caso o estoque tenha mudado.
        _carrinho.removeWhere((id, _) => _produto(id) == null);
        for (final id in _carrinho.keys.toList()) {
          final estoque = _produto(id)!.quantidadeEstoque;
          if (estoque <= 0) {
            _carrinho.remove(id);
          } else if (_carrinho[id]! > estoque) {
            _carrinho[id] = estoque;
          }
        }
        if (_cliente != null && !_clientes.any((c) => c.id == _cliente!.id)) {
          _cliente = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _erroCarga = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Produto? _produto(int id) {
    for (final p in _produtos) {
      if (p.id == id) return p;
    }
    return null;
  }

  double get _total => _carrinho.entries.fold(0.0, (soma, e) {
        final p = _produto(e.key);
        return p == null ? soma : soma + p.preco * e.value;
      });

  int get _totalItens => _carrinho.values.fold(0, (s, q) => s + q);

  // ---------------------------------------------------------------
  // Seleção de cliente e produtos
  // ---------------------------------------------------------------

  Future<void> _escolherCliente() async {
    final escolhido = await showModalBottomSheet<Cliente>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.superficie,
      builder: (_) => _SeletorLista<Cliente>(
        titulo: 'Selecionar cliente',
        dicaBusca: 'Nome ou CPF',
        itens: _clientes,
        filtro: (c, termo) {
          final digitos = Formatadores.somenteDigitos(termo);
          return c.nome.toLowerCase().contains(termo) ||
              (digitos.isNotEmpty &&
                  Formatadores.somenteDigitos(c.cpf).contains(digitos));
        },
        construir: (c) => ListTile(
          leading: const Icon(Icons.person_rounded),
          title: Text(c.nome),
          subtitle: Text('CPF ${Formatadores.cpf(c.cpf)}'),
        ),
      ),
    );
    if (escolhido != null) setState(() => _cliente = escolhido);
  }

  Future<void> _adicionarProduto() async {
    final disponiveis = _produtos
        .where((p) => p.quantidadeEstoque - (_carrinho[p.id] ?? 0) > 0)
        .toList();

    final escolhido = await showModalBottomSheet<Produto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.superficie,
      builder: (_) => _SeletorLista<Produto>(
        titulo: 'Adicionar produto',
        dicaBusca: 'Nome ou categoria',
        itens: disponiveis,
        filtro: (p, termo) =>
            p.nome.toLowerCase().contains(termo) ||
            p.categoria.toLowerCase().contains(termo),
        construir: (p) => ListTile(
          leading: const Icon(Icons.chair_rounded, color: Cores.verde),
          title: Text(p.nome),
          subtitle: Text(
            '${Formatadores.moeda(p.preco)} · '
            '${p.quantidadeEstoque - (_carrinho[p.id] ?? 0)} disponível(is)',
          ),
        ),
      ),
    );
    if (escolhido != null) {
      setState(() => _carrinho[escolhido.id] = (_carrinho[escolhido.id] ?? 0) + 1);
    }
  }

  void _alterarQuantidade(int produtoId, int delta) {
    final p = _produto(produtoId);
    if (p == null) return;
    final atual = _carrinho[produtoId] ?? 0;
    final nova = atual + delta;
    if (delta > 0) {
      final erro = Validadores.quantidade(nova, p.quantidadeEstoque);
      if (erro != null) {
        mostrarMensagem(context, erro);
        return;
      }
    }
    setState(() {
      if (nova <= 0) {
        _carrinho.remove(produtoId);
      } else {
        _carrinho[produtoId] = nova;
      }
    });
  }

  void _limpar() {
    setState(() {
      _cliente = null;
      _carrinho.clear();
      _forma = null;
      _parcelas = 1;
    });
  }

  // ---------------------------------------------------------------
  // Finalização
  // ---------------------------------------------------------------

  Future<void> _finalizar() async {
    if (_cliente == null) {
      mostrarMensagem(context, 'Selecione o cliente.', erro: true);
      return;
    }
    if (_carrinho.isEmpty) {
      mostrarMensagem(context, 'Adicione pelo menos um produto.', erro: true);
      return;
    }
    if (!_cliente!.ativo) {
      mostrarMensagem(context, 'Este cliente está inativo.', erro: true);
      return;
    }
    // Confere cada item de novo, com os dados mais recentes carregados.
    for (final item in _carrinho.entries) {
      final p = _produto(item.key);
      if (p == null || !p.ativo) {
        mostrarMensagem(context, 'Um produto do carrinho não está mais disponível.',
            erro: true);
        setState(() => _carrinho.remove(item.key));
        return;
      }
      final erro = Validadores.quantidade(item.value, p.quantidadeEstoque);
      if (erro != null) {
        mostrarMensagem(context, '${p.nome}: $erro', erro: true);
        return;
      }
    }
    if (_total <= 0) {
      mostrarMensagem(context, 'O total da venda deve ser maior que zero.', erro: true);
      return;
    }
    if (_forma == null) {
      mostrarMensagem(context, 'Escolha a forma de pagamento.', erro: true);
      return;
    }
    final parcelas = FormasPagamento.permiteParcelar(_forma) ? _parcelas : 1;
    if (_enviando) return; // evita envio duplicado por toque duplo

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar venda'),
        content: Text(
          'Cliente: ${_cliente!.nome}\n'
          'Itens: $_totalItens\n'
          'Total: ${Formatadores.moeda(_total)}\n'
          'Pagamento: ${FormasPagamento.nome(_forma)}'
          '${parcelas > 1 ? ' em ${parcelas}x' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final itens = _carrinho.entries.map((e) {
      final p = _produto(e.key)!;
      return ItemVenda(
        produtoId: p.id,
        produtoNome: p.nome,
        quantidade: e.value,
        precoUnitario: p.preco,
        subtotal: p.preco * e.value,
      );
    }).toList();

    setState(() => _enviando = true);
    final sync = context.read<SyncService>();

    try {
      final resultado = await sync.registrarVenda(
        clienteId: _cliente!.id,
        clienteNome: _cliente!.nome,
        itens: itens,
        formaPagamento: _forma!,
        parcelas: parcelas,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            resultado.ficouPendente
                ? Icons.cloud_upload_rounded
                : Icons.check_circle_rounded,
            color: resultado.ficouPendente ? Cores.alerta : Cores.verde,
            size: 48,
          ),
          title: Text(resultado.ficouPendente
              ? 'Venda guardada no aparelho'
              : 'Venda #${resultado.venda!.id} registrada'),
          content: Text(resultado.ficouPendente
              ? 'O servidor não respondeu. A venda será enviada automaticamente '
                  'assim que a conexão voltar. Acompanhe na aba Vendas.'
              : 'Total: ${Formatadores.moeda(resultado.venda!.valorTotal)}\n'
                  'O estoque foi atualizado no servidor.'),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      _limpar();
      widget.aoConcluir();
      if (resultado.ficouPendente) recarregar();
    } on ApiException catch (e) {
      // Ex.: "Estoque insuficiente para o produto X." (dados do celular
      // estavam desatualizados). Recarrega para mostrar o estoque real.
      if (!mounted) return;
      mostrarMensagem(context, e.mensagem, erro: true);
      recarregar();
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ---------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    observarSincronizacao(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova venda'),
        actions: [
          if (_cliente != null || _carrinho.isNotEmpty)
            TextButton(onPressed: _limpar, child: const Text('Limpar')),
        ],
      ),
      body: Column(
        children: [
          const BannerSincronizacao(),
          Expanded(child: _conteudo()),
        ],
      ),
      bottomNavigationBar: _carregando || _erroCarga != null ? null : _rodape(),
    );
  }

  Widget _conteudo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erroCarga != null && _produtos.isEmpty) {
      return EstadoErro(mensagem: _erroCarga!, aoTentar: recarregar);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_usandoCache)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Modo offline: estoque e preços conforme a última atualização. '
              'A venda será conferida pelo servidor no envio.',
              style: TextStyle(color: Cores.alerta, fontSize: 12),
            ),
          ),
        const TituloSecao('1. Cliente'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: ListTile(
              leading: Icon(
                _cliente == null ? Icons.person_search_rounded : Icons.person_rounded,
                color: Cores.verde,
              ),
              title: Text(_cliente?.nome ?? 'Selecionar cliente'),
              subtitle: _cliente == null
                  ? const Text('Toque para escolher')
                  : Text('CPF ${Formatadores.cpf(_cliente!.cpf)}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _escolherCliente,
            ),
          ),
        ),
        TituloSecao(
          '2. Produtos',
          acao: TextButton.icon(
            onPressed: _adicionarProduto,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar'),
          ),
        ),
        if (_carrinho.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _adicionarProduto,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Adicionar produto'),
            ),
          )
        else
          ..._carrinho.entries.map((e) {
            final p = _produto(e.key)!;
            return Padding(
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
                            Text(p.nome,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '${Formatadores.moeda(p.preco)} x ${e.value} = '
                              '${Formatadores.moeda(p.preco * e.value)}',
                              style: const TextStyle(
                                  color: Cores.textoSecundario, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: e.value == 1
                            ? 'Remover ${p.nome}'
                            : 'Diminuir quantidade de ${p.nome}',
                        icon: Icon(e.value == 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove_circle_outline_rounded),
                        onPressed: () => _alterarQuantidade(p.id, -1),
                      ),
                      Semantics(
                        label: 'Quantidade: ${e.value}',
                        excludeSemantics: true,
                        child: Text('${e.value}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        tooltip: 'Aumentar quantidade de ${p.nome}',
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        onPressed: e.value >= p.quantidadeEstoque
                            ? null
                            : () => _alterarQuantidade(p.id, 1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const TituloSecao('3. Pagamento'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final forma in FormasPagamento.venda)
                ChoiceChip(
                  label: Text(FormasPagamento.nome(forma)),
                  selected: _forma == forma,
                  onSelected: (_) => setState(() {
                    _forma = forma;
                    if (!FormasPagamento.permiteParcelar(forma)) _parcelas = 1;
                  }),
                ),
            ],
          ),
        ),
        if (FormasPagamento.permiteParcelar(_forma))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<int>(
              value: _parcelas,
              decoration: const InputDecoration(labelText: 'Parcelas'),
              items: [
                for (var n = 1; n <= 12; n++)
                  DropdownMenuItem(
                    value: n,
                    child: Text(_total > 0
                        ? '${n}x de ${Formatadores.moeda((_total / n * 100).floor() / 100)}'
                        : '${n}x'),
                  ),
              ],
              onChanged: (v) => setState(() => _parcelas = v ?? 1),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            _forma == null
                ? 'Dinheiro, Pix e débito são recebidos na hora. Crédito, boleto e '
                    'crediário geram parcelas a receber, a primeira em 30 dias.'
                : FormasPagamento.permiteParcelar(_forma)
                    ? 'As parcelas ficam em aberto no Financeiro até serem recebidas.'
                    : 'Recebido na hora: a conta a receber já entra como recebida.',
            style: const TextStyle(color: Cores.textoSecundario, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _rodape() {
    return SafeArea(
      top: false,
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
                label: 'Total da venda: ${Formatadores.moeda(_total)}',
                excludeSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_totalItens item(ns)',
                        style: const TextStyle(color: Cores.textoSecundario)),
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
                onPressed: _enviando ? null : _finalizar,
                child: _enviando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Finalizar venda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Folha inferior com busca, usada para escolher cliente ou produto.
class _SeletorLista<T> extends StatefulWidget {
  const _SeletorLista({
    required this.titulo,
    required this.dicaBusca,
    required this.itens,
    required this.filtro,
    required this.construir,
  });

  final String titulo;
  final String dicaBusca;
  final List<T> itens;
  final bool Function(T item, String termo) filtro;
  final Widget Function(T item) construir;

  @override
  State<_SeletorLista<T>> createState() => _SeletorListaState<T>();
}

class _SeletorListaState<T> extends State<_SeletorLista<T>> {
  final _busca = TextEditingController();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final termo = _busca.text.trim().toLowerCase();
    final itens = termo.isEmpty
        ? widget.itens
        : widget.itens.where((i) => widget.filtro(i, termo)).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Cores.borda,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CampoBusca(
              controller: _busca,
              dica: widget.dicaBusca,
              aoMudar: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: itens.isEmpty
                ? const EstadoVazio(
                    icone: Icons.search_off_rounded,
                    titulo: 'Nada encontrado',
                  )
                : ListView.builder(
                    controller: scroll,
                    itemCount: itens.length,
                    itemBuilder: (context, i) => InkWell(
                      onTap: () => Navigator.pop(context, itens[i]),
                      child: IgnorePointer(child: widget.construir(itens[i])),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
