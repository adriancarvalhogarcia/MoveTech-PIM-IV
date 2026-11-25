/// Resultado de uma consulta que pode ter vindo da API ou do cache.
///
/// Estratégia "rede primeiro, cache como reserva": a tela sempre tenta
/// buscar dados atualizados; se o servidor estiver inacessível, mostra
/// a última cópia salva e informa desde quando ela é válida.
class DadosCarregados<T> {
  const DadosCarregados(this.dados, {this.doCache = false, this.atualizadoEm});

  final T dados;
  final bool doCache;
  final DateTime? atualizadoEm;
}
