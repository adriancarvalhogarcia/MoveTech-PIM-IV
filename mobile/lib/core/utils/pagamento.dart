/// Formas de pagamento aceitas pela API (Models/Constantes.cs).
class FormasPagamento {
  FormasPagamento._();

  static const nomes = <String, String>{
    'Dinheiro': 'Dinheiro',
    'Pix': 'Pix',
    'CartaoDebito': 'Cartão de débito',
    'CartaoCredito': 'Cartão de crédito',
    'Boleto': 'Boleto',
    'Crediario': 'Crediário',
    'Transferencia': 'Transferência',
    'NaoInformada': 'Não informada',
  };

  /// Formas aceitas ao registrar uma venda.
  static const venda = [
    'Dinheiro',
    'Pix',
    'CartaoDebito',
    'CartaoCredito',
    'Boleto',
    'Crediario',
  ];

  /// Formas aceitas ao baixar uma conta ou pagar um reembolso.
  static const baixa = [
    'Dinheiro',
    'Pix',
    'CartaoDebito',
    'CartaoCredito',
    'Boleto',
    'Transferencia',
  ];

  /// Recebidas na hora: a conta a receber já nasce baixada (1 parcela).
  static const aVista = ['Dinheiro', 'Pix', 'CartaoDebito'];

  static String nome(String? forma) => nomes[forma] ?? (forma ?? '-');

  static bool permiteParcelar(String? forma) =>
      forma != null && !aVista.contains(forma);
}
