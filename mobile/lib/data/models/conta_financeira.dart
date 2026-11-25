import '../../core/utils/formatadores.dart';

/// Conta a pagar ou a receber (GET /api/financeiro).
class ContaFinanceira {
  const ContaFinanceira({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.origem,
    required this.numeroParcela,
    required this.totalParcelas,
    required this.valor,
    required this.status,
    required this.vencida,
    this.vencimento,
    this.cliente,
    this.fornecedor,
    this.vendaId,
    this.notaEntradaId,
    this.dataPagamento,
    this.valorPago,
    this.formaPagamento,
    this.observacao,
  });

  final int id;

  /// Receber ou Pagar.
  final String tipo;
  final String descricao;

  /// Venda, NotaEntrada, Devolucao ou Manual.
  final String origem;
  final int numeroParcela;
  final int totalParcelas;
  final double valor;

  /// Aberta, Paga ou Cancelada.
  final String status;
  final bool vencida;
  final DateTime? vencimento;
  final String? cliente;
  final String? fornecedor;
  final int? vendaId;
  final int? notaEntradaId;
  final DateTime? dataPagamento;
  final double? valorPago;
  final String? formaPagamento;
  final String? observacao;

  bool get receber => tipo == 'Receber';
  bool get aberta => status == 'Aberta';
  bool get paga => status == 'Paga';
  bool get cancelada => status == 'Cancelada';
  bool get manual => origem == 'Manual';

  String get origemExibicao => switch (origem) {
        'Venda' => 'Venda',
        'NotaEntrada' => 'Nota de entrada',
        'Devolucao' => 'Reembolso de devolução',
        'Manual' => 'Lançamento avulso',
        _ => origem,
      };

  String get situacao {
    if (paga) return receber ? 'Recebida' : 'Paga';
    if (cancelada) return 'Cancelada';
    if (vencida) return 'Vencida';
    return 'Em aberto';
  }

  String? get parte => cliente ?? fornecedor;

  factory ContaFinanceira.fromJson(Map<String, dynamic> json) => ContaFinanceira(
        id: Formatadores.lerInteiro(json['id']),
        tipo: json['tipo']?.toString() ?? 'Receber',
        descricao: json['descricao']?.toString() ?? '',
        origem: json['origem']?.toString() ?? '',
        numeroParcela: Formatadores.lerInteiro(json['numeroParcela'] ?? 1),
        totalParcelas: Formatadores.lerInteiro(json['totalParcelas'] ?? 1),
        valor: Formatadores.lerDecimal(json['valor']),
        status: json['status']?.toString() ?? 'Aberta',
        vencida: json['vencida'] == true,
        vencimento: Formatadores.lerDataSimples(json['vencimento']),
        cliente: json['cliente']?.toString(),
        fornecedor: json['fornecedor']?.toString(),
        vendaId: json['vendaId'] == null ? null : Formatadores.lerInteiro(json['vendaId']),
        notaEntradaId: json['notaEntradaId'] == null
            ? null
            : Formatadores.lerInteiro(json['notaEntradaId']),
        dataPagamento: Formatadores.lerDataSimples(json['dataPagamento']),
        valorPago: json['valorPago'] == null ? null : Formatadores.lerDecimal(json['valorPago']),
        formaPagamento: json['formaPagamento']?.toString(),
        observacao: json['observacao']?.toString(),
      );
}

/// Linha do histórico de uma conta (baixa, estorno, ajuste...).
class HistoricoConta {
  const HistoricoConta({required this.acao, this.detalhe, this.usuarioNome, this.criadoEm});

  final String acao;
  final String? detalhe;
  final String? usuarioNome;
  final DateTime? criadoEm;

  factory HistoricoConta.fromJson(Map<String, dynamic> json) => HistoricoConta(
        acao: json['acao']?.toString() ?? '',
        detalhe: json['detalhe']?.toString(),
        usuarioNome: json['usuarioNome']?.toString(),
        criadoEm: Formatadores.lerDataApi(json['criadoEm']),
      );
}

/// GET /api/financeiro/resumo
class ResumoFinanceiro {
  const ResumoFinanceiro({
    required this.aReceber,
    required this.aPagar,
    required this.receberVencido,
    required this.pagarVencido,
    required this.recebidoMes,
    required this.pagoMes,
    required this.saldoPrevisto,
  });

  final double aReceber;
  final double aPagar;
  final double receberVencido;
  final double pagarVencido;
  final double recebidoMes;
  final double pagoMes;
  final double saldoPrevisto;

  factory ResumoFinanceiro.fromJson(Map<String, dynamic> json) => ResumoFinanceiro(
        aReceber: Formatadores.lerDecimal(json['aReceber']),
        aPagar: Formatadores.lerDecimal(json['aPagar']),
        receberVencido: Formatadores.lerDecimal(json['receberVencido']),
        pagarVencido: Formatadores.lerDecimal(json['pagarVencido']),
        recebidoMes: Formatadores.lerDecimal(json['recebidoMes']),
        pagoMes: Formatadores.lerDecimal(json['pagoMes']),
        saldoPrevisto: Formatadores.lerDecimal(json['saldoPrevisto']),
      );
}
