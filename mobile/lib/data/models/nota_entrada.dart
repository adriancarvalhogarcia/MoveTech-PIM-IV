import '../../core/utils/formatadores.dart';

/// Nota de entrada já lançada (GET /api/notas-entrada).
class NotaEntradaResumo {
  const NotaEntradaResumo({
    required this.id,
    required this.numero,
    required this.serie,
    required this.fornecedor,
    required this.fornecedorDocumento,
    required this.valorTotal,
    required this.quantidadeItens,
    this.dataEmissao,
    this.criadoEm,
    this.usuarioNome,
  });

  final int id;
  final String numero;
  final String serie;
  final String fornecedor;
  final String fornecedorDocumento;
  final double valorTotal;
  final int quantidadeItens;
  final DateTime? dataEmissao;
  final DateTime? criadoEm;
  final String? usuarioNome;

  factory NotaEntradaResumo.fromJson(Map<String, dynamic> json) => NotaEntradaResumo(
        id: Formatadores.lerInteiro(json['id']),
        numero: json['numero']?.toString() ?? '',
        serie: json['serie']?.toString() ?? '',
        fornecedor: json['fornecedor']?.toString() ?? '',
        fornecedorDocumento: json['fornecedorDocumento']?.toString() ?? '',
        valorTotal: Formatadores.lerDecimal(json['valorTotal']),
        quantidadeItens: Formatadores.lerInteiro(json['quantidadeItens']),
        dataEmissao: Formatadores.lerDataSimples(json['dataEmissao']),
        criadoEm: Formatadores.lerDataApi(json['criadoEm']),
        usuarioNome: json['usuarioNome']?.toString(),
      );
}

/// Item da prévia da nota (POST /api/notas-entrada/previa) com a decisão
/// do usuário: somar a um produto existente ou cadastrar um novo.
class ItemPreviaNota {
  ItemPreviaNota({
    required this.numeroItem,
    required this.codigo,
    required this.descricao,
    required this.quantidade,
    required this.quantidadeInteira,
    required this.custoUnitario,
    required this.custoTotal,
    required this.precoSugerido,
    required this.acao,
    this.codigoBarras,
    this.unidade,
    this.produtoId,
    this.produtoSugeridoNome,
    this.motivoSugestao,
  })  : nome = descricao.length > 120 ? descricao.substring(0, 120) : descricao,
        precoVenda = precoSugerido;

  final int numeroItem;
  final String codigo;
  final String descricao;
  final String? codigoBarras;
  final String? unidade;
  final double quantidade;
  final bool quantidadeInteira;
  final double custoUnitario;
  final double custoTotal;
  final double precoSugerido;
  final String? produtoSugeridoNome;
  final String? motivoSugestao;

  // Decisão (editável na tela)
  String acao; // vincular | criar
  int? produtoId;
  String nome;
  String categoria = 'Geral';
  double precoVenda;
  bool precoEditado = false;
  int estoqueMinimo = 0;

  factory ItemPreviaNota.fromJson(Map<String, dynamic> json) {
    final sugerido = json['produtoSugerido'];
    return ItemPreviaNota(
      numeroItem: Formatadores.lerInteiro(json['numeroItem']),
      codigo: json['codigo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      codigoBarras: json['codigoBarras']?.toString(),
      unidade: json['unidade']?.toString(),
      quantidade: Formatadores.lerDecimal(json['quantidade']),
      quantidadeInteira: json['quantidadeInteira'] != false,
      custoUnitario: Formatadores.lerDecimal(json['custoUnitario']),
      custoTotal: Formatadores.lerDecimal(json['custoTotal']),
      precoSugerido: Formatadores.lerDecimal(json['precoSugerido']),
      acao: json['acaoSugerida']?.toString() ?? 'criar',
      produtoId: sugerido is Map ? Formatadores.lerInteiro(sugerido['id']) : null,
      produtoSugeridoNome: sugerido is Map ? sugerido['nome']?.toString() : null,
      motivoSugestao: sugerido is Map ? sugerido['motivo']?.toString() : null,
    );
  }

  Map<String, dynamic> decisao() => acao == 'vincular'
      ? {'numeroItem': numeroItem, 'acao': 'vincular', 'produtoId': produtoId}
      : {
          'numeroItem': numeroItem,
          'acao': 'criar',
          'nome': nome.trim(),
          'categoria': categoria.trim().isEmpty ? 'Geral' : categoria.trim(),
          'precoVenda': double.parse(precoVenda.toStringAsFixed(2)),
          'estoqueMinimo': estoqueMinimo,
        };
}

class DuplicataNota {
  const DuplicataNota({required this.numero, required this.valor, this.vencimento});

  final String numero;
  final double valor;
  final DateTime? vencimento;

  factory DuplicataNota.fromJson(Map<String, dynamic> json) => DuplicataNota(
        numero: json['numero']?.toString() ?? '',
        valor: Formatadores.lerDecimal(json['valor']),
        vencimento: Formatadores.lerDataSimples(json['vencimento']),
      );
}

/// Resultado da prévia: cabeçalho da nota + itens + duplicatas.
class PreviaNota {
  PreviaNota({
    required this.chaveAcesso,
    required this.numero,
    required this.serie,
    required this.valorTotal,
    required this.jaImportada,
    required this.fornecedorNome,
    required this.fornecedorDocumento,
    required this.fornecedorCadastrado,
    required this.itens,
    required this.duplicatas,
    this.dataEmissao,
  });

  final String chaveAcesso;
  final String numero;
  final String serie;
  final double valorTotal;
  final bool jaImportada;
  final String fornecedorNome;
  final String fornecedorDocumento;
  final bool fornecedorCadastrado;
  final DateTime? dataEmissao;
  final List<ItemPreviaNota> itens;
  final List<DuplicataNota> duplicatas;

  factory PreviaNota.fromJson(Map<String, dynamic> json) {
    final f = Map<String, dynamic>.from(json['fornecedor'] as Map? ?? const {});
    return PreviaNota(
      chaveAcesso: json['chaveAcesso']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      serie: json['serie']?.toString() ?? '',
      valorTotal: Formatadores.lerDecimal(json['valorTotal']),
      jaImportada: json['jaImportada'] == true,
      fornecedorNome: f['razaoSocial']?.toString() ?? '',
      fornecedorDocumento: f['documento']?.toString() ?? '',
      fornecedorCadastrado: f['cadastrado'] == true,
      dataEmissao: Formatadores.lerDataSimples(json['dataEmissao']),
      itens: (json['itens'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => ItemPreviaNota.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      duplicatas: (json['duplicatas'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => DuplicataNota.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
