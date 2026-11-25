import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import '../data/local/armazenamento_local.dart';
import '../data/models/venda.dart';
import '../data/models/venda_pendente.dart';
import '../data/repositories/produto_repository.dart';
import '../data/repositories/venda_repository.dart';

/// Resultado do registro de uma venda pelo aplicativo.
class ResultadoRegistroVenda {
  const ResultadoRegistroVenda.enviada(this.venda) : pendente = null;
  const ResultadoRegistroVenda.naFila(this.pendente) : venda = null;

  /// Preenchido quando a API confirmou a venda.
  final Venda? venda;

  /// Preenchido quando a venda ficou guardada no aparelho.
  final VendaPendente? pendente;

  bool get ficouPendente => pendente != null;
}

/// Sincronização de dados entre o aparelho e a API.
///
/// Funcionamento:
/// 1. Ao registrar uma venda, o app tenta enviá-la na hora.
/// 2. Se o servidor não responder, a venda vai para uma fila local
///    (shared_preferences) e o estoque é descontado no cache.
/// 3. A fila é reenviada automaticamente a cada 30 segundos, quando o
///    app volta para o primeiro plano ou quando o usuário toca em
///    "Sincronizar agora".
/// 4. Se a API recusar uma venda da fila (ex.: o estoque acabou
///    enquanto o vendedor estava offline), ela fica marcada como
///    "rejeitada" com o motivo, para o vendedor decidir o que fazer.
class SyncService extends ChangeNotifier {
  SyncService(this._local, this._vendas, this._produtos);

  final ArmazenamentoLocal _local;
  final VendaRepository _vendas;
  final ProdutoRepository _produtos;

  final List<VendaPendente> _fila = [];
  Timer? _timer;
  bool _sincronizando = false;
  DateTime? _ultimaSincronizacao;
  String? _ultimaMensagem;

  /// Incrementado sempre que vendas da fila chegam ao servidor.
  /// As telas usam para saber que precisam recarregar os dados.
  int _versaoDados = 0;

  List<VendaPendente> get fila => List.unmodifiable(_fila);
  int get totalAguardando =>
      _fila.where((v) => v.status != StatusPendente.rejeitada).length;
  int get totalRejeitadas =>
      _fila.where((v) => v.status == StatusPendente.rejeitada).length;
  bool get sincronizando => _sincronizando;
  DateTime? get ultimaSincronizacao => _ultimaSincronizacao;
  String? get ultimaMensagem => _ultimaMensagem;
  int get versaoDados => _versaoDados;

  // ---------------------------------------------------------------
  // Persistência da fila
  // ---------------------------------------------------------------

  Future<void> carregarFila() async {
    final json = _local.lerJson(ChavesArmazenamento.filaVendas);
    _fila
      ..clear()
      ..addAll(
        (json?['itens'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => VendaPendente.fromJson(Map<String, dynamic>.from(e))),
      );
    // Uma venda que estava "enviando" quando o app fechou volta à fila.
    for (final v in _fila) {
      if (v.status == StatusPendente.enviando) {
        v.status = StatusPendente.aguardando;
      }
    }
    // O agendamento só começa depois do login (HomeShell chama sincronizar()).
    notifyListeners();
  }

  Future<void> _salvarFila() => _local.salvarJson(
        ChavesArmazenamento.filaVendas,
        {'itens': _fila.map((v) => v.toJson()).toList()},
      );

  // ---------------------------------------------------------------
  // Registro de venda (online ou offline)
  // ---------------------------------------------------------------

  Future<ResultadoRegistroVenda> registrarVenda({
    required int clienteId,
    required String clienteNome,
    required List<ItemVenda> itens,
    required String formaPagamento,
    int parcelas = 1,
  }) async {
    final pendente = VendaPendente(
      idLocal: 'local-${DateTime.now().microsecondsSinceEpoch}',
      clienteId: clienteId,
      clienteNome: clienteNome,
      itens: itens,
      criadoEm: DateTime.now(),
      formaPagamento: formaPagamento,
      parcelas: parcelas,
    );

    try {
      final venda = await _vendas.registrar(pendente.corpoApi());
      _versaoDados++;
      notifyListeners();
      return ResultadoRegistroVenda.enviada(venda);
    } on SemConexaoException {
      _fila.add(pendente);
      await _salvarFila();
      await _produtos.baixarEstoqueLocal({
        for (final item in itens) item.produtoId: item.quantidade,
      });
      _agendar();
      notifyListeners();
      return ResultadoRegistroVenda.naFila(pendente);
    }
    // ApiException (estoque insuficiente, cliente inativo...) sobe para a tela.
  }

  // ---------------------------------------------------------------
  // Envio da fila
  // ---------------------------------------------------------------

  Future<void> sincronizar() async {
    if (_sincronizando) return;
    final aEnviar =
        _fila.where((v) => v.status == StatusPendente.aguardando).toList();
    if (aEnviar.isEmpty) {
      _agendar();
      return;
    }

    _sincronizando = true;
    _ultimaMensagem = null;
    notifyListeners();

    var enviadas = 0;
    try {
      for (final venda in aEnviar) {
        venda
          ..status = StatusPendente.enviando
          ..tentativas += 1;
        notifyListeners();

        try {
          await _vendas.registrar(venda.corpoApi());
          _fila.remove(venda);
          enviadas++;
        } on SemConexaoException {
          venda.status = StatusPendente.aguardando;
          _ultimaMensagem = 'Servidor inacessível. Nova tentativa em breve.';
          break;
        } on ApiException catch (e) {
          if (e.erroDeNegocio) {
            venda
              ..status = StatusPendente.rejeitada
              ..mensagemErro = e.mensagem;
          } else {
            // 401 (sessão expirada) ou erro 5xx: tenta de novo depois.
            venda.status = StatusPendente.aguardando;
            _ultimaMensagem = e.mensagem;
            break;
          }
        }
        await _salvarFila();
      }
    } finally {
      await _salvarFila();
      _sincronizando = false;
      if (enviadas > 0) {
        _versaoDados++;
        _ultimaSincronizacao = DateTime.now();
        _ultimaMensagem = enviadas == 1
            ? '1 venda sincronizada com o servidor.'
            : '$enviadas vendas sincronizadas com o servidor.';
      }
      _agendar();
      notifyListeners();
    }
  }

  /// Coloca uma venda rejeitada de volta na fila (ex.: depois que o
  /// estoque foi reposto na área administrativa).
  Future<void> tentarNovamente(String idLocal) async {
    for (final v in _fila) {
      if (v.idLocal == idLocal) {
        v
          ..status = StatusPendente.aguardando
          ..mensagemErro = null;
      }
    }
    await _salvarFila();
    notifyListeners();
    await sincronizar();
  }

  Future<void> descartar(String idLocal) async {
    _fila.removeWhere((v) => v.idLocal == idLocal);
    await _salvarFila();
    _versaoDados++; // o estoque do cache precisa ser recarregado
    _agendar();
    notifyListeners();
  }

  /// Avisa as telas que dados mudaram no servidor (cliente ou produto
  /// cadastrado/editado), para recarregarem suas listas na hora.
  void notificarAlteracaoDados() {
    _versaoDados++;
    notifyListeners();
  }

  /// Mantém um timer ativo somente enquanto houver vendas aguardando.
  void _agendar() {
    if (totalAguardando == 0) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(
      AppConfig.intervaloSincronizacao,
      (_) => sincronizar(),
    );
  }

  void pararAgendamento() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
