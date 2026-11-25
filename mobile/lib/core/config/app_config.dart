/// Configurações gerais do aplicativo.
///
/// O endereço da API pode ser alterado pelo usuário na tela de login
/// (ícone de engrenagem), pois o IP do computador que roda o backend
/// muda de rede para rede.
class AppConfig {
  AppConfig._();

  static const String nomeApp = 'MoveTech';

  /// Endereço padrão da API.
  ///
  /// 10.0.2.2 é o "localhost" do computador visto de dentro do
  /// emulador Android. Em um celular físico, use o IP do computador
  /// na rede Wi-Fi, por exemplo: http://192.168.0.10:5071/api
  ///
  /// O valor pode ser definido na compilação, sem alterar o código:
  ///   flutter build apk --dart-define=API_URL=http://192.168.0.10:5071/api
  /// (é o que o script gerar_apk.ps1 faz, com o IP do computador).
  static const String urlApiPadrao = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5071/api',
  );

  /// Tempo máximo de espera de uma requisição antes de considerar
  /// o servidor inacessível (modo offline).
  static const Duration tempoLimiteRequisicao = Duration(seconds: 12);

  /// Intervalo da sincronização automática enquanto houver vendas
  /// aguardando envio.
  static const Duration intervaloSincronizacao = Duration(seconds: 30);
}

/// Chaves usadas no armazenamento local.
class ChavesArmazenamento {
  ChavesArmazenamento._();

  // flutter_secure_storage (criptografado)
  static const String token = 'movetech_token';

  // shared_preferences
  static const String usuario = 'movetech_usuario';
  static const String urlApi = 'movetech_url_api';
  static const String cacheProdutos = 'movetech_cache_produtos';
  static const String cacheClientes = 'movetech_cache_clientes';
  static const String cacheVendas = 'movetech_cache_vendas';
  static const String cacheDashboard = 'movetech_cache_dashboard';
  static const String filaVendas = 'movetech_fila_vendas';
}
