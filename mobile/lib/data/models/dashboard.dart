import '../../core/utils/formatadores.dart';

/// Resposta de GET /api/relatorios/dashboard.
class Dashboard {
  const Dashboard({
    required this.totalClientesAtivos,
    required this.totalProdutosAtivos,
    required this.totalProdutosEstoqueBaixo,
    required this.totalVendas,
    required this.faturamentoTotal,
    required this.ticketMedio,
    required this.estoqueBaixo,
    required this.maisVendidos,
    required this.vendasRecentes,
  });

  final int totalClientesAtivos;
  final int totalProdutosAtivos;
  final int totalProdutosEstoqueBaixo;
  final int totalVendas;
  final double faturamentoTotal;
  final double ticketMedio;
  final List<EstoqueBaixoResumo> estoqueBaixo;
  final List<MaisVendido> maisVendidos;
  final List<VendaRecente> vendasRecentes;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final resumo = Map<String, dynamic>.from(json['resumo'] as Map? ?? {});

    List<T> lista<T>(String chave, T Function(Map<String, dynamic>) conv) =>
        (json[chave] as List? ?? const [])
            .whereType<Map>()
            .map((e) => conv(Map<String, dynamic>.from(e)))
            .toList();

    return Dashboard(
      totalClientesAtivos: Formatadores.lerInteiro(resumo['totalClientesAtivos']),
      totalProdutosAtivos: Formatadores.lerInteiro(resumo['totalProdutosAtivos']),
      totalProdutosEstoqueBaixo:
          Formatadores.lerInteiro(resumo['totalProdutosEstoqueBaixo']),
      totalVendas: Formatadores.lerInteiro(resumo['totalVendas']),
      faturamentoTotal: Formatadores.lerDecimal(resumo['faturamentoTotal']),
      ticketMedio: Formatadores.lerDecimal(resumo['ticketMedio']),
      estoqueBaixo: lista('produtosEstoqueBaixo', EstoqueBaixoResumo.fromJson),
      maisVendidos: lista('produtosMaisVendidos', MaisVendido.fromJson),
      vendasRecentes: lista('vendasRecentes', VendaRecente.fromJson),
    );
  }
}

class EstoqueBaixoResumo {
  const EstoqueBaixoResumo(this.id, this.nome, this.quantidade, this.minimo);

  final int id;
  final String nome;
  final int quantidade;
  final int minimo;

  factory EstoqueBaixoResumo.fromJson(Map<String, dynamic> j) =>
      EstoqueBaixoResumo(
        Formatadores.lerInteiro(j['id']),
        j['nome']?.toString() ?? '',
        Formatadores.lerInteiro(j['quantidadeEstoque']),
        Formatadores.lerInteiro(j['estoqueMinimo']),
      );
}

class MaisVendido {
  const MaisVendido(this.produto, this.quantidade, this.faturamento);

  final String produto;
  final int quantidade;
  final double faturamento;

  factory MaisVendido.fromJson(Map<String, dynamic> j) => MaisVendido(
        j['produto']?.toString() ?? '',
        Formatadores.lerInteiro(j['quantidadeVendida']),
        Formatadores.lerDecimal(j['faturamento']),
      );
}

class VendaRecente {
  const VendaRecente(this.id, this.cliente, this.valor, this.data);

  final int id;
  final String cliente;
  final double valor;
  final DateTime? data;

  factory VendaRecente.fromJson(Map<String, dynamic> j) {
    final c = j['cliente'];
    return VendaRecente(
      Formatadores.lerInteiro(j['id']),
      c is Map ? (c['nome']?.toString() ?? '') : (c?.toString() ?? ''),
      Formatadores.lerDecimal(j['valorTotal']),
      Formatadores.lerDataApi(j['criadoEm']),
    );
  }
}
