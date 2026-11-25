/// Erro devolvido pela API (resposta HTTP com status de erro).
class ApiException implements Exception {
  ApiException(this.statusCode, this.mensagem, {this.dados});

  final int statusCode;
  final String mensagem;

  /// Corpo da resposta, quando existir (ex.: estoqueDisponivel).
  final Map<String, dynamic>? dados;

  bool get naoAutorizado => statusCode == 401;

  /// Erros de regra de negócio (dados inválidos, conflito, não encontrado).
  /// Reenviar a mesma requisição não vai resolver.
  bool get erroDeNegocio =>
      statusCode == 400 || statusCode == 404 || statusCode == 409;

  @override
  String toString() => mensagem;
}

/// O servidor não pôde ser alcançado (sem internet, API desligada,
/// IP errado ou tempo limite esgotado).
class SemConexaoException implements Exception {
  SemConexaoException([
    this.mensagem =
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
  ]);

  final String mensagem;

  @override
  String toString() => mensagem;
}
