import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatadores.dart';
import '../local/armazenamento_local.dart';
import '../models/cliente.dart';
import 'dados_carregados.dart';

/// Clientes: GET, POST e PUT em /api/clientes.
///
/// Cadastro e edição exigem conexão, porque a API precisa validar o
/// CPF (não pode haver dois clientes com o mesmo CPF).
class ClienteRepository {
  ClienteRepository(this._api, this._local);

  final ApiClient _api;
  final ArmazenamentoLocal _local;

  Future<DadosCarregados<List<Cliente>>> listar() async {
    try {
      final resposta = await _api.get('/clientes') as List;
      final clientes = resposta
          .whereType<Map>()
          .map((e) => Cliente.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await _salvarCache(clientes);
      return DadosCarregados(clientes);
    } on SemConexaoException {
      final registro = _local.lerCache(ChavesArmazenamento.cacheClientes);
      if (registro == null || registro.dados is! List) rethrow;
      return DadosCarregados(
        _converter(registro.dados as List),
        doCache: true,
        atualizadoEm: registro.atualizadoEm,
      );
    }
  }

  Future<Cliente> criar({
    required String nome,
    required String cpf,
    String? telefone,
    String? email,
    String? endereco,
  }) async {
    final resposta = await _api.post(
      '/clientes',
      corpo: Cliente.corpoRequisicao(
        nome: nome,
        cpf: cpf,
        telefone: telefone,
        email: email,
        endereco: endereco,
      ),
    );
    final cliente = Cliente.fromJson(Map<String, dynamic>.from(resposta as Map));
    await _atualizarNoCache(cliente);
    return cliente;
  }

  Future<Cliente> atualizar(
    int id, {
    required String nome,
    required String cpf,
    String? telefone,
    String? email,
    String? endereco,
    required bool ativo,
  }) async {
    final resposta = await _api.put(
      '/clientes/$id',
      corpo: Cliente.corpoRequisicao(
        nome: nome,
        cpf: cpf,
        telefone: telefone,
        email: email,
        endereco: endereco,
        ativo: ativo,
      ),
    );
    final cliente = Cliente.fromJson(Map<String, dynamic>.from(resposta as Map));
    await _atualizarNoCache(cliente);
    return cliente;
  }

  /// Confere no cache se já existe outro cliente com o mesmo CPF.
  /// É só uma checagem antecipada para avisar o usuário mais cedo;
  /// a validação que vale é a da API (HTTP 409).
  Cliente? buscarPorCpfNoCache(String cpf, {int? ignorarId}) {
    final digitos = Formatadores.somenteDigitos(cpf);
    if (digitos.length != 11) return null;
    final registro = _local.lerCache(ChavesArmazenamento.cacheClientes);
    if (registro?.dados is! List) return null;
    for (final c in _converter(registro!.dados as List)) {
      if (c.id != ignorarId && Formatadores.somenteDigitos(c.cpf) == digitos) {
        return c;
      }
    }
    return null;
  }

  List<Cliente> _converter(List lista) => lista
      .whereType<Map>()
      .map((e) => Cliente.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  Future<void> _salvarCache(List<Cliente> clientes) => _local.salvarCache(
        ChavesArmazenamento.cacheClientes,
        clientes.map((c) => c.toJson()).toList(),
      );

  Future<void> _atualizarNoCache(Cliente cliente) async {
    final registro = _local.lerCache(ChavesArmazenamento.cacheClientes);
    final lista =
        registro?.dados is List ? _converter(registro!.dados as List) : <Cliente>[];
    final indice = lista.indexWhere((c) => c.id == cliente.id);
    if (indice >= 0) {
      lista[indice] = cliente;
    } else {
      lista.add(cliente);
    }
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    await _salvarCache(lista);
  }
}
