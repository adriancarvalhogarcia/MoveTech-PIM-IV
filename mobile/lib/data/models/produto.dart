import '../../core/utils/formatadores.dart';

/// Espelha a entidade Produto do backend (Models/Produto.cs).
class Produto {
  const Produto({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.preco,
    required this.quantidadeEstoque,
    required this.estoqueMinimo,
    this.descricao,
    this.ativo = true,
    this.criadoEm,
  });

  final int id;
  final String nome;
  final String? descricao;
  final String categoria;
  final double preco;
  final int quantidadeEstoque;
  final int estoqueMinimo;
  final bool ativo;
  final DateTime? criadoEm;

  /// Mesma regra do endpoint GET /api/produtos/estoque-baixo.
  bool get estoqueBaixo => ativo && quantidadeEstoque <= estoqueMinimo;
  bool get semEstoque => quantidadeEstoque <= 0;
  bool get disponivelParaVenda => ativo && quantidadeEstoque > 0;

  Produto copiarComEstoque(int novoEstoque) => Produto(
        id: id,
        nome: nome,
        descricao: descricao,
        categoria: categoria,
        preco: preco,
        quantidadeEstoque: novoEstoque,
        estoqueMinimo: estoqueMinimo,
        ativo: ativo,
        criadoEm: criadoEm,
      );

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        id: Formatadores.lerInteiro(json['id']),
        nome: json['nome']?.toString() ?? '',
        descricao: json['descricao']?.toString(),
        categoria: json['categoria']?.toString() ?? 'Sem categoria',
        preco: Formatadores.lerDecimal(json['preco']),
        quantidadeEstoque: Formatadores.lerInteiro(json['quantidadeEstoque']),
        estoqueMinimo: Formatadores.lerInteiro(json['estoqueMinimo']),
        ativo: json['ativo'] != false,
        criadoEm: Formatadores.lerDataApi(json['criadoEm']),
      );

  /// Corpo de POST /api/produtos (CriarProdutoDto) e de
  /// PUT /api/produtos/{id} (AtualizarProdutoDto, que inclui "ativo").
  static Map<String, dynamic> corpoRequisicao({
    required String nome,
    String? descricao,
    required String categoria,
    required double preco,
    required int quantidadeEstoque,
    required int estoqueMinimo,
    bool? ativo,
  }) {
    final desc = descricao?.trim();
    final corpo = <String, dynamic>{
      'nome': nome.trim(),
      'descricao': (desc == null || desc.isEmpty) ? null : desc,
      'categoria': categoria.trim(),
      'preco': double.parse(preco.toStringAsFixed(2)),
      'quantidadeEstoque': quantidadeEstoque,
      'estoqueMinimo': estoqueMinimo,
    };
    if (ativo != null) corpo['ativo'] = ativo;
    return corpo;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'categoria': categoria,
        'preco': preco,
        'quantidadeEstoque': quantidadeEstoque,
        'estoqueMinimo': estoqueMinimo,
        'ativo': ativo,
        'criadoEm': criadoEm?.toUtc().toIso8601String(),
      };
}
