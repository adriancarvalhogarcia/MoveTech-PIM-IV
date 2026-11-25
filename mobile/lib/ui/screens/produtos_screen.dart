import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatadores.dart';
import '../../data/models/produto.dart';
import '../../data/repositories/dados_carregados.dart';
import '../../data/repositories/produto_repository.dart';
import '../../core/network/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../widgets/componentes.dart';
import '../widgets/recarregar_ao_sincronizar.dart';
import 'produto_form_screen.dart';

/// Catálogo e estoque: GET /api/produtos.
/// O perfil Administrador também cadastra produtos (botão Novo produto).
class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen>
    with RecarregarAoSincronizar {
  final _busca = TextEditingController();
  DadosCarregados<List<Produto>>? _dados;
  String? _erro;
  bool _carregando = true;
  String? _categoria;
  bool _somenteEstoqueBaixo = false;

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
      final dados = await context.read<ProdutoRepository>().listar();
      if (mounted) setState(() => _dados = dados);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Produto> get _filtrados {
    final termo = _busca.text.trim().toLowerCase();
    return (_dados?.dados ?? const <Produto>[]).where((p) {
      if (!p.ativo) return false;
      if (_categoria != null && p.categoria != _categoria) return false;
      if (_somenteEstoqueBaixo && !p.estoqueBaixo) return false;
      if (termo.isEmpty) return true;
      return p.nome.toLowerCase().contains(termo) ||
          p.categoria.toLowerCase().contains(termo) ||
          (p.descricao ?? '').toLowerCase().contains(termo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    observarSincronizacao(context);

    final categorias = <String>{
      for (final p in _dados?.dados ?? const <Produto>[])
        if (p.ativo) p.categoria,
    }.toList()
      ..sort();

    final administrador =
        context.select<AuthService, bool>((a) => a.usuario?.administrador ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      floatingActionButton: administrador
          ? FloatingActionButton.extended(
              onPressed: () async {
                final salvo = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const ProdutoFormScreen()),
                );
                if (salvo == true) recarregar();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo produto'),
            )
          : null,
      body: Column(
        children: [
          const BannerSincronizacao(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: CampoBusca(
              controller: _busca,
              dica: 'Buscar por nome ou categoria',
              aoMudar: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('Estoque baixo'),
                    avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                    selected: _somenteEstoqueBaixo,
                    onSelected: (v) => setState(() => _somenteEstoqueBaixo = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('Todas'),
                    selected: _categoria == null,
                    onSelected: (_) => setState(() => _categoria = null),
                  ),
                ),
                ...categorias.map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _categoria == c,
                      onSelected: (s) => setState(() => _categoria = s ? c : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_dados?.doCache == true) AvisoCache(atualizadoEm: _dados!.atualizadoEm),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_dados == null) {
      return EstadoErro(mensagem: _erro ?? 'Erro desconhecido.', aoTentar: recarregar);
    }

    final produtos = _filtrados;
    if (produtos.isEmpty) {
      return RefreshIndicator(
        onRefresh: recarregar,
        child: ListView(
          children: const [
            SizedBox(height: 60),
            EstadoVazio(
              icone: Icons.chair_outlined,
              titulo: 'Nenhum produto encontrado',
              mensagem: 'Ajuste a busca ou os filtros.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: recarregar,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96, top: 4),
        itemCount: produtos.length,
        separatorBuilder: (_, __) => const Divider(indent: 16, endIndent: 16),
        itemBuilder: (context, i) => _ItemProduto(produto: produtos[i]),
      ),
    );
  }
}

class _ItemProduto extends StatelessWidget {
  const _ItemProduto({required this.produto});

  final Produto produto;

  @override
  Widget build(BuildContext context) {
    final p = produto;
    final Color corEstoque =
        p.semEstoque ? Cores.erro : (p.estoqueBaixo ? Cores.alerta : Cores.verde);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Cores.superficie2,
        child: const Icon(Icons.chair_rounded, color: Cores.verde),
      ),
      title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${p.categoria} · ${Formatadores.moeda(p.preco)}'),
      trailing: Selo(
        p.semEstoque ? 'Sem estoque' : '${p.quantidadeEstoque} un.',
        cor: corEstoque,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProdutoDetalheScreen(produto: p)),
      ),
    );
  }
}

/// Detalhe de um produto. Para o Administrador: entrada de estoque e edição.
class ProdutoDetalheScreen extends StatefulWidget {
  const ProdutoDetalheScreen({super.key, required this.produto});

  final Produto produto;

  @override
  State<ProdutoDetalheScreen> createState() => _ProdutoDetalheScreenState();
}

class _ProdutoDetalheScreenState extends State<ProdutoDetalheScreen> {
  late Produto _produto;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _produto = widget.produto;
  }

  Future<void> _entradaEstoque() async {
    final quantidade = await pedirQuantidadeEntrada(context, _produto);
    if (quantidade == null || !mounted) return;

    final repo = context.read<ProdutoRepository>();
    final sync = context.read<SyncService>();
    setState(() => _processando = true);
    try {
      final atualizado = await repo.entradaEstoque(_produto.id, quantidade);
      sync.notificarAlteracaoDados();
      if (!mounted) return;
      setState(() => _produto = atualizado);
      mostrarMensagem(
        context,
        'Entrada de $quantidade unidade(s). Estoque agora: ${atualizado.quantidadeEstoque}.',
      );
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } on SemConexaoException catch (e) {
      if (mounted) {
        mostrarMensagem(context, '${e.mensagem} A entrada não foi registrada.', erro: true);
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _editar() async {
    final repo = context.read<ProdutoRepository>();
    final salvo = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProdutoFormScreen(produto: _produto)),
    );
    if (salvo != true || !mounted) return;
    try {
      final atualizado = await repo.buscar(_produto.id);
      if (mounted) setState(() => _produto = atualizado);
    } catch (_) {
      // Sem conexão para recarregar: a lista será atualizada depois.
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _produto;
    final administrador =
        context.select<AuthService, bool>((a) => a.usuario?.administrador ?? false);
    final Color corEstoque =
        p.semEstoque ? Cores.erro : (p.estoqueBaixo ? Cores.alerta : Cores.verde);
    final String situacao = !p.ativo
        ? 'Inativo'
        : p.semEstoque
            ? 'Sem estoque'
            : (p.estoqueBaixo ? 'Estoque baixo' : 'Estoque adequado');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produto'),
        actions: [
          if (administrador)
            IconButton(
              tooltip: 'Editar produto',
              icon: const Icon(Icons.edit_rounded),
              onPressed: _processando ? null : _editar,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Cores.superficie2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Cores.borda),
            ),
            child: const Icon(Icons.chair_rounded, size: 72, color: Cores.verde),
          ),
          const SizedBox(height: 16),
          Text(p.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Selo(p.categoria, cor: Cores.textoSecundario),
              Selo(situacao, cor: p.ativo ? corEstoque : Cores.textoSecundario),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            Formatadores.moeda(p.preco),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Cores.verde,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _Linha('Estoque atual', '${p.quantidadeEstoque} unidade(s)'),
                const Divider(),
                _Linha('Estoque mínimo', '${p.estoqueMinimo} unidade(s)'),
                const Divider(),
                _Linha('Código', '#${p.id}'),
                const Divider(),
                _Linha('Cadastrado em', Formatadores.data(p.criadoEm)),
              ],
            ),
          ),
          if (administrador) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _processando ? null : _entradaEstoque,
              icon: _processando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.add_box_rounded),
              label: const Text('Entrada de estoque'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _processando ? null : _editar,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Editar produto'),
            ),
          ],
          if ((p.descricao ?? '').trim().isNotEmpty) ...[
            const TituloSecao('Descrição'),
            Text(p.descricao!, style: const TextStyle(height: 1.4)),
          ],
          if (!administrador) ...[
            const SizedBox(height: 16),
            const Text(
              'Cadastro, preço e estoque são alterados por um usuário Administrador.',
              style: TextStyle(color: Cores.textoSecundario, fontSize: 12),
            ),
          ],
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(rotulo, style: const TextStyle(color: Cores.textoSecundario)),
          ),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
