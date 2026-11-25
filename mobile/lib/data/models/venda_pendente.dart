import '../../core/utils/formatadores.dart';
import 'venda.dart';

enum StatusPendente { aguardando, enviando, rejeitada }

/// Venda registrada sem conexão, guardada no aparelho até ser
/// enviada para POST /api/vendas pelo SyncService.
class VendaPendente {
  VendaPendente({
    required this.idLocal,
    required this.clienteId,
    required this.clienteNome,
    required this.itens,
    required this.criadoEm,
    this.status = StatusPendente.aguardando,
    this.mensagemErro,
    this.tentativas = 0,
    this.formaPagamento,
    this.parcelas = 1,
  });

  /// Forma de pagamento escolhida (null em vendas guardadas por versões antigas).
  final String? formaPagamento;
  final int parcelas;

  /// Identificador gerado no aparelho (a venda ainda não tem Id do banco).
  final String idLocal;
  final int clienteId;
  final String clienteNome;
  final List<ItemVenda> itens;
  final DateTime criadoEm;
  StatusPendente status;
  String? mensagemErro;
  int tentativas;

  /// Valor calculado com os preços do cache no momento da venda.
  /// O valor oficial é recalculado pela API no envio.
  double get valorEstimado => itens.fold(0.0, (s, i) => s + i.subtotal);

  /// Corpo de POST /api/vendas (CriarVendaDto).
  Map<String, dynamic> corpoApi() => {
        'clienteId': clienteId,
        'itens': itens
            .map((i) => {'produtoId': i.produtoId, 'quantidade': i.quantidade})
            .toList(),
        if (formaPagamento != null) 'formaPagamento': formaPagamento,
        'parcelas': parcelas,
      };

  factory VendaPendente.fromJson(Map<String, dynamic> json) => VendaPendente(
        idLocal: json['idLocal']?.toString() ?? '',
        clienteId: Formatadores.lerInteiro(json['clienteId']),
        clienteNome: json['clienteNome']?.toString() ?? '',
        itens: (json['itens'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ItemVenda.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        criadoEm: Formatadores.lerDataApi(json['criadoEm']) ?? DateTime.now(),
        status: StatusPendente.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => StatusPendente.aguardando,
        ),
        mensagemErro: json['mensagemErro']?.toString(),
        tentativas: Formatadores.lerInteiro(json['tentativas']),
        formaPagamento: json['formaPagamento']?.toString(),
        parcelas: json['parcelas'] == null ? 1 : Formatadores.lerInteiro(json['parcelas']),
      );

  Map<String, dynamic> toJson() => {
        'idLocal': idLocal,
        'clienteId': clienteId,
        'clienteNome': clienteNome,
        'itens': itens.map((i) => i.toJson()).toList(),
        'criadoEm': criadoEm.toUtc().toIso8601String(),
        'status': status.name,
        'mensagemErro': mensagemErro,
        'tentativas': tentativas,
        'formaPagamento': formaPagamento,
        'parcelas': parcelas,
      };
}
