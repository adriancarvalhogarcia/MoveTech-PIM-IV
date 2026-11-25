/// Funções de formatação no padrão brasileiro.
///
/// Foram escritas sem o pacote intl para evitar conflito de versões
/// com o SDK do Flutter.
class Formatadores {
  Formatadores._();

  /// 1234.5 -> "R$ 1.234,50"
  static String moeda(num? valor) {
    final v = (valor ?? 0).toDouble();
    final negativo = v < 0;
    final centavosTotais = (v.abs() * 100).round();
    final inteiro = centavosTotais ~/ 100;
    final centavos = centavosTotais % 100;

    final digitos = inteiro.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      final restante = digitos.length - i;
      buffer.write(digitos[i]);
      if (restante > 1 && restante % 3 == 1) buffer.write('.');
    }

    final texto = 'R\$ ${buffer.toString()},${centavos.toString().padLeft(2, '0')}';
    return negativo ? '- $texto' : texto;
  }

  static String _doisDigitos(int n) => n.toString().padLeft(2, '0');

  /// "28/09/2026"
  static String data(DateTime? data) {
    if (data == null) return '-';
    final d = data.toLocal();
    return '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year}';
  }

  /// "28/09/2026 14:35"
  static String dataHora(DateTime? data) {
    if (data == null) return '-';
    final d = data.toLocal();
    return '${Formatadores.data(d)} ${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';
  }

  /// "há 5 min", "há 2 h", "em 12/09/2026"
  static String tempoRelativo(DateTime? data) {
    if (data == null) return 'nunca';
    final diferenca = DateTime.now().difference(data.toLocal());
    if (diferenca.inSeconds < 60) return 'agora mesmo';
    if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
    if (diferenca.inHours < 24) return 'há ${diferenca.inHours} h';
    return 'em ${Formatadores.data(data)}';
  }

  /// "12345678909" -> "123.456.789-09"
  static String cpf(String? valor) {
    final d = somenteDigitos(valor ?? '');
    if (d.length != 11) return valor ?? '';
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  /// "11987654321" -> "(11) 98765-4321" · "1133334444" -> "(11) 3333-4444"
  /// Aceita texto parcial (usado na máscara enquanto o usuário digita).
  static String telefone(String? valor) {
    var d = somenteDigitos(valor ?? '');
    if (d.isEmpty) return '';
    // Número salvo com o código do país (+55): mantém só DDD + número.
    if (d.length > 11 && d.startsWith('55')) d = d.substring(2);
    final buffer = StringBuffer('(');
    final corte = d.length > 10 ? 7 : 6; // posição do hífen
    for (var i = 0; i < d.length && i < 11; i++) {
      if (i == 2) buffer.write(') ');
      if (i == corte) buffer.write('-');
      buffer.write(d[i]);
    }
    return buffer.toString();
  }

  static String somenteDigitos(String valor) =>
      valor.replaceAll(RegExp(r'[^0-9]'), '');

  /// As datas do backend (DateTime.UtcNow gravado no MySQL) chegam sem
  /// fuso, ex.: "2026-08-22T17:06:49.123". Elas são UTC, então o sufixo
  /// "Z" é acrescentado antes da conversão para o horário local.
  static DateTime? lerDataApi(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString();
    if (texto.isEmpty) return null;
    final temFuso = texto.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(texto);
    return DateTime.tryParse(temFuso ? texto : '${texto}Z')?.toLocal();
  }

  static double lerDecimal(dynamic valor) {
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  static int lerInteiro(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? 0;
    return 0;
  }

  /// Datas sem horário (vencimentos, emissão): "2026-11-19" ou
  /// "2026-11-19T00:00:00". Lidas como data local, sem conversão de fuso.
  static DateTime? lerDataSimples(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString();
    if (texto.length < 10) return null;
    final partes = texto.substring(0, 10).split('-');
    if (partes.length != 3) return null;
    final ano = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final dia = int.tryParse(partes[2]);
    if (ano == null || mes == null || dia == null) return null;
    return DateTime(ano, mes, dia);
  }

  /// "19/11/2026" sem conversão de fuso (para datas simples).
  static String dataSimples(DateTime? data) {
    if (data == null) return '-';
    return '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';
  }

  /// "2026-11-19" para enviar à API.
  static String isoData(DateTime data) =>
      '${data.year}-${_doisDigitos(data.month)}-${_doisDigitos(data.day)}';

  /// CNPJ ou CPF formatado.
  static String documento(String? valor) {
    final d = somenteDigitos(valor ?? '');
    if (d.length == 14) {
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/'
          '${d.substring(8, 12)}-${d.substring(12)}';
    }
    if (d.length == 11) return cpf(d);
    return d;
  }
}
