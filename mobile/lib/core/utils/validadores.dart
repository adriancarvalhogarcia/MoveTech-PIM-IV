import 'formatadores.dart';

/// Validações de formulário. Retornam null quando o valor é válido
/// ou a mensagem de erro que será exibida abaixo do campo.
class Validadores {
  Validadores._();

  static String? obrigatorio(String? valor, {String campo = 'Campo'}) {
    if (valor == null || valor.trim().isEmpty) return '$campo é obrigatório.';
    return null;
  }

  static String? email(String? valor, {bool obrigatorio = true}) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return obrigatorio ? 'Informe o e-mail.' : null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    return ok ? null : 'E-mail inválido.';
  }

  /// Valida os dígitos verificadores do CPF.
  static String? cpf(String? valor) {
    final d = Formatadores.somenteDigitos(valor ?? '');
    if (d.isEmpty) return 'Informe o CPF.';
    if (d.length != 11) return 'O CPF deve ter 11 dígitos.';
    if (RegExp(r'^(\d)\1{10}$').hasMatch(d)) return 'CPF inválido.';

    int calcularDigito(int tamanho) {
      var soma = 0;
      for (var i = 0; i < tamanho; i++) {
        soma += int.parse(d[i]) * (tamanho + 1 - i);
      }
      final resto = (soma * 10) % 11;
      return resto == 10 ? 0 : resto;
    }

    if (calcularDigito(9) != int.parse(d[9]) ||
        calcularDigito(10) != int.parse(d[10])) {
      return 'CPF inválido.';
    }
    return null;
  }

  static String? tamanhoMaximo(String? valor, int maximo) {
    if (valor != null && valor.trim().length > maximo) {
      return 'Máximo de $maximo caracteres.';
    }
    return null;
  }

  /// Nome de pessoa: obrigatório, de 3 a 120 caracteres (mesmo limite
  /// do CriarClienteDto), só letras, espaços, apóstrofo, ponto e hífen.
  static String? nomePessoa(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Informe o nome.';
    if (v.length < 3) return 'O nome deve ter pelo menos 3 letras.';
    if (v.length > 120) return 'Máximo de 120 caracteres.';
    if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' .\-]+$").hasMatch(v)) {
      return 'Use apenas letras no nome.';
    }
    return null;
  }

  /// Telefone brasileiro (opcional): DDD + 8 ou 9 dígitos.
  static String? telefone(String? valor) {
    final d = Formatadores.somenteDigitos(valor ?? '');
    if (d.isEmpty) return null;
    if (d.length != 10 && d.length != 11) {
      return 'Informe DDD + número (10 ou 11 dígitos).';
    }
    if (d.startsWith('0')) return 'O DDD não começa com zero.';
    if (d.length == 11 && d[2] != '9') {
      return 'Celular deve começar com 9 após o DDD.';
    }
    return null;
  }

  /// Senha do login: obrigatória. O tamanho mínimo é regra do cadastro
  /// de usuários (área administrativa web), não do login.
  static String? senha(String? valor) {
    if (valor == null || valor.isEmpty) return 'Informe a senha.';
    if (valor.length > 100) return 'Senha longa demais.';
    return null;
  }

  /// Endereço da API: precisa ser http(s)://host[:porta][/caminho].
  static String? urlApi(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Informe o endereço do servidor.';
    if (v.contains(' ')) return 'O endereço não pode ter espaços.';
    final uri = Uri.tryParse(v);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Formato esperado: http://192.168.0.10:5071/api';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'O endereço deve começar com http:// ou https://';
    }
    return null;
  }

  /// Preço de produto: maior que zero (CriarProdutoDto: Range(0.01, ...)).
  static String? preco(double? valor) {
    if (valor == null || valor <= 0) return 'Informe um preço maior que zero.';
    if (valor > 99999999.99) return 'Preço acima do limite permitido.';
    return null;
  }

  /// Número inteiro de 0 até [maximo] (estoque, estoque mínimo).
  static String? inteiroNaoNegativo(String? valor, {String campo = 'O valor', int maximo = 999999}) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Informe ${campo.toLowerCase()}.';
    final n = int.tryParse(v);
    if (n == null) return 'Use apenas números inteiros.';
    if (n < 0) return '$campo não pode ser negativo.';
    if (n > maximo) return 'Máximo de $maximo.';
    return null;
  }

  /// Quantidade de um item da venda: de 1 até o estoque disponível.
  static String? quantidade(int quantidade, int estoque) {
    if (quantidade < 1) return 'A quantidade mínima é 1.';
    if (quantidade > estoque) {
      return 'Estoque disponível: $estoque unidade(s).';
    }
    return null;
  }
}
