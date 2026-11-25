import '../../core/utils/formatadores.dart';

/// Espelha a entidade Cliente do backend (Models/Cliente.cs).
class Cliente {
  const Cliente({
    required this.id,
    required this.nome,
    required this.cpf,
    this.telefone,
    this.email,
    this.endereco,
    this.ativo = true,
    this.criadoEm,
  });

  final int id;
  final String nome;
  final String cpf;
  final String? telefone;
  final String? email;
  final String? endereco;
  final bool ativo;
  final DateTime? criadoEm;

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: Formatadores.lerInteiro(json['id']),
        nome: json['nome']?.toString() ?? '',
        cpf: json['cpf']?.toString() ?? '',
        telefone: _textoOuNulo(json['telefone']),
        email: _textoOuNulo(json['email']),
        endereco: _textoOuNulo(json['endereco']),
        ativo: json['ativo'] != false,
        criadoEm: Formatadores.lerDataApi(json['criadoEm']),
      );

  /// Formato usado no cache local.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'cpf': cpf,
        'telefone': telefone,
        'email': email,
        'endereco': endereco,
        'ativo': ativo,
        'criadoEm': criadoEm?.toUtc().toIso8601String(),
      };

  /// Corpo de POST /api/clientes (CriarClienteDto)
  /// e de PUT /api/clientes/{id} (AtualizarClienteDto, que inclui "ativo").
  static Map<String, dynamic> corpoRequisicao({
    required String nome,
    required String cpf,
    String? telefone,
    String? email,
    String? endereco,
    bool? ativo,
  }) {
    final corpo = <String, dynamic>{
      'nome': nome.trim(),
      'cpf': Formatadores.cpf(cpf),
      // Campos opcionais vazios vão como null: o [EmailAddress] do
      // ASP.NET rejeita string vazia.
      'telefone': _textoOuNulo(telefone),
      'email': _textoOuNulo(email),
      'endereco': _textoOuNulo(endereco),
    };
    if (ativo != null) corpo['ativo'] = ativo;
    return corpo;
  }

  static String? _textoOuNulo(dynamic valor) {
    final texto = valor?.toString().trim();
    return (texto == null || texto.isEmpty) ? null : texto;
  }
}
