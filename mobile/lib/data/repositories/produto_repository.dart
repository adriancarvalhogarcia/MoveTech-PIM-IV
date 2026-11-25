import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../local/armazenamento_local.dart';
import '../models/produto.dart';
import 'dados_carregados.dart';

/// Produtos: GET, POST e PUT em /api/produtos.
///
/// Consulta para todos os perfis; cadastro, edição e entrada de estoque
/// aparecem no app só para o perfil Administrador. Todas as alterações
/// exigem conexão, porque o estoque é compartilhado com a web.
class ProdutoRepository {
  ProdutoRepository(this._api, this._local);

  final ApiClient _api;
  final ArmazenamentoLocal _local;

  Future<DadosCarregados<List<Produto>>> listar() async {
    try {
      final resposta = await _api.get('/produtos') as List;
      final produtos = resposta
          .whereType<Map>()
          .map((e) => Produto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await _local.salvarCache(
        ChavesArmazenamento.cacheProdutos,
        produtos.map((p) => p.toJson()).toList(),
      );
      return DadosCarregados(produtos);
    } on SemConexaoException {
      final cache = _lerDoCache();
      if (cache == null) rethrow;
      return cache;
    }
  }

  Future<Produto> buscar(int id) async {
    final resposta = await _api.get('/produtos/$id');
    return Produto.fromJson(Map<String, dynamic>.from(resposta as Map));
  }

  Future<Produto> criar({
    required String nome,
    String? descricao,
    required String categoria,
    required double preco,
    required int quantidadeEstoque,
    required int estoqueMinimo,
  }) async {
    final resposta = await _api.post(
      '/produtos',
      corpo: Produto.corpoRequisicao(
        nome: nome,
        descricao: descricao,
        categoria: categoria,
        preco: preco,
        quantidadeEstoque: quantidadeEstoque,
        estoqueMinimo: estoqueMinimo,
      ),
    );
    final produto = Produto.fromJson(Map<String, dynamic>.from(resposta as Map));
    await _atualizarNoCache(produto);
    return produto;
  }

  Future<Produto> atualizar(
    int id, {
    required String nome,
    String? descricao,
    required String categoria,
    required double preco,
    required int quantidadeEstoque,
    required int estoqueMinimo,
    required bool ativo,
  }) async {
    final resposta = await _api.put(
      '/produtos/$id',
      corpo: Produto.corpoRequisicao(
        nome: nome,
        descricao: descricao,
        categoria: categoria,
        preco: preco,
        quantidadeEstoque: quantidadeEstoque,
        estoqueMinimo: estoqueMinimo,
        ativo: ativo,
      ),
    );
    final produto = Produto.fromJson(Map<String, dynamic>.from(resposta as Map));
    await _atualizarNoCache(produto);
    return produto;
  }

  /// Entrada de mercadoria: soma [quantidade] ao estoque atual.
  ///
  /// O estoque é lido de novo na API imediatamente antes de gravar, para
  /// não desfazer uma venda feita pela web ou por outro celular desde a
  /// última vez que a lista foi carregada.
  Future<Produto> entradaEstoque(int id, int quantidade) async {
    final atual = await buscar(id);
    return atualizar(
      id,
      nome: atual.nome,
      descricao: atual.descricao,
      categoria: atual.categoria,
      preco: atual.preco,
      quantidadeEstoque: atual.quantidadeEstoque + quantidade,
      estoqueMinimo: atual.estoqueMinimo,
      ativo: atual.ativo,
    );
  }

  /// Categorias já usadas, para sugerir no cadastro.
  List<String> categoriasNoCache() {
    final cache = _lerDoCache();
    if (cache == null) return const [];
    final categorias = cache.dados.map((p) => p.categoria).toSet().toList()..sort();
    return categorias;
  }

  Future<void> _atualizarNoCache(Produto produto) async {
    final cache = _lerDoCache();
    final lista = cache?.dados.toList() ?? <Produto>[];
    final indice = lista.indexWhere((p) => p.id == produto.id);
    if (indice >= 0) {
      lista[indice] = produto;
    } else {
      lista.add(produto);
    }
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    await _local.salvarCache(
      ChavesArmazenamento.cacheProdutos,
      lista.map((p) => p.toJson()).toList(),
    );
  }

  DadosCarregados<List<Produto>>? _lerDoCache() {
    final registro = _local.lerCache(ChavesArmazenamento.cacheProdutos);
    if (registro == null || registro.dados is! List) return null;
    final produtos = (registro.dados as List)
        .whereType<Map>()
        .map((e) => Produto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return DadosCarregados(
      produtos,
      doCache: true,
      atualizadoEm: registro.atualizadoEm,
    );
  }

  /// Após uma venda offline, desconta o estoque no cache local para que
  /// o vendedor não venda de novo uma unidade que já saiu.
  /// Quando a venda for sincronizada, a lista é recarregada da API.
  Future<void> baixarEstoqueLocal(Map<int, int> quantidadesPorProduto) async {
    final cache = _lerDoCache();
    if (cache == null) return;
    final atualizados = cache.dados.map((p) {
      final baixa = quantidadesPorProduto[p.id];
      if (baixa == null) return p;
      final novo = p.quantidadeEstoque - baixa;
      return p.copiarComEstoque(novo < 0 ? 0 : novo);
    }).toList();
    await _local.salvarCache(
      ChavesArmazenamento.cacheProdutos,
      atualizados.map((p) => p.toJson()).toList(),
    );
  }
}
