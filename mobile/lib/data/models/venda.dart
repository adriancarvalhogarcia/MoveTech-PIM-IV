import '../../core/utils/formatadores.dart';

/// Item de uma venda (Models/ItemVenda.cs).
class ItemVenda {
  const ItemVenda({
    required this.produtoId,
    required this.produtoNome,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.id,
    this.quantidadeDevolvida = 0,
  });

  final int? id;

  /// Quanto deste item já voltou por devolução.
  final int quantidadeDevolvida;

  int get disponivelParaDevolver => quantidade - quantidadeDevolvida;
  final int produtoId;
  final String produtoNome;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;

  factory ItemVenda.fromJson(Map<String, dynamic> json) {
    final produto = json['produto'];
    final quantidade = Formatadores.lerInteiro(json['quantidade']);
    final preco = Formatadores.lerDecimal(json['precoUnitario']);
    return ItemVenda(
      id: json['id'] == null ? null : Formatadores.lerInteiro(json['id']),
      produtoId: Formatadores.lerInteiro(json['produtoId']),
      produtoNome: produto is Map
          ? (produto['nome']?.toString() ?? '')
          : (json['produtoNome']?.toString() ?? 'Produto #${json['produtoId']}'),
      quantidade: quantidade,
      precoUnitario: preco,
      subtotal: json['subtotal'] == null
          ? preco * quantidade
          : Formatadores.lerDecimal(json['subtotal']),
      quantidadeDevolvida: Formatadores.lerInteiro(json['quantidadeDevolvida']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'produtoId': produtoId,
        'produtoNome': produtoNome,
        'quantidade': quantidade,
        'precoUnitario': precoUnitario,
        'subtotal': subtotal,
        'quantidadeDevolvida': quantidadeDevolvida,
      };
}

/// Venda registrada no servidor (GET /api/vendas).
class Venda {
  const Venda({
    required this.id,
    required this.clienteId,
    required this.clienteNome,
    required this.valorTotal,
    required this.itens,
    this.criadoEm,
    this.formaPagamento = 'NaoInformada',
    this.parcelas = 1,
    this.valorDevolvido = 0,
    this.status = 'Concluida',
    this.devolucoes = const [],
  });

  final int id;
  final String formaPagamento;
  final int parcelas;
  final double valorDevolvido;

  /// Concluida, DevolvidaParcial ou Devolvida.
  final String status;
  final List<DevolucaoResumo> devolucoes;

  double get valorLiquido => valorTotal - valorDevolvido;
  bool get totalmenteDevolvida => status == 'Devolvida';
  bool get devolvidaParcial => status == 'DevolvidaParcial';
  final int clienteId;
  final String clienteNome;
  final double valorTotal;
  final DateTime? criadoEm;
  final List<ItemVenda> itens;

  int get quantidadeItens => itens.fold(0, (soma, i) => soma + i.quantidade);

  factory Venda.fromJson(Map<String, dynamic> json) {
    // GET devolve "cliente": { id, nome }; o POST devolve "cliente": "Nome".
    final cliente = json['cliente'];
    final String nomeCliente;
    if (cliente is Map) {
      nomeCliente = cliente['nome']?.toString() ?? '';
    } else if (cliente != null) {
      nomeCliente = cliente.toString();
    } else {
      nomeCliente = json['clienteNome']?.toString() ?? '';
    }

    final itensJson = json['itens'];
    return Venda(
      id: Formatadores.lerInteiro(json['id']),
      clienteId: Formatadores.lerInteiro(json['clienteId']),
      clienteNome: nomeCliente,
      valorTotal: Formatadores.lerDecimal(json['valorTotal']),
      criadoEm: Formatadores.lerDataApi(json['criadoEm']),
      formaPagamento: json['formaPagamento']?.toString() ?? 'NaoInformada',
      parcelas: Formatadores.lerInteiro(json['parcelas'] ?? 1),
      valorDevolvido: Formatadores.lerDecimal(json['valorDevolvido']),
      status: json['status']?.toString() ?? 'Concluida',
      devolucoes: json['devolucoes'] is List
          ? (json['devolucoes'] as List)
              .whereType<Map>()
              .map((e) => DevolucaoResumo.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      itens: itensJson is List
          ? itensJson
              .whereType<Map>()
              .map((e) => ItemVenda.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clienteId': clienteId,
        'clienteNome': clienteNome,
        'valorTotal': valorTotal,
        'criadoEm': criadoEm?.toUtc().toIso8601String(),
        'formaPagamento': formaPagamento,
        'parcelas': parcelas,
        'valorDevolvido': valorDevolvido,
        'status': status,
        'itens': itens.map((i) => i.toJson()).toList(),
      };
}

/// Devolução registrada em uma venda (GET /api/vendas/{id}).
class DevolucaoResumo {
  const DevolucaoResumo({
    required this.id,
    required this.motivo,
    required this.valorTotal,
    required this.itens,
    this.usuarioNome,
    this.criadoEm,
  });

  final int id;
  final String motivo;
  final double valorTotal;
  final String? usuarioNome;
  final DateTime? criadoEm;

  /// Ex.: "2x Sofá 3 lugares, 1x Rack"
  final String itens;

  factory DevolucaoResumo.fromJson(Map<String, dynamic> json) => DevolucaoResumo(
        id: Formatadores.lerInteiro(json['id']),
        motivo: json['motivo']?.toString() ?? '',
        valorTotal: Formatadores.lerDecimal(json['valorTotal']),
        usuarioNome: json['usuarioNome']?.toString(),
        criadoEm: Formatadores.lerDataApi(json['criadoEm']),
        itens: (json['itens'] as List? ?? const [])
            .whereType<Map>()
            .map((i) => '${i['quantidade']}x ${i['produto']}')
            .join(', '),
      );
}
