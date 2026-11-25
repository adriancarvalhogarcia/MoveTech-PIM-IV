/// Usuário autenticado (retornado por POST /api/auth/login).
class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  final int id;
  final String nome;
  final String email;
  final String perfil;

  bool get administrador => perfil.toLowerCase().startsWith('admin');

  /// Nome do perfil para exibição ("Funcionario" chega sem acento da API).
  String get perfilExibicao => administrador ? 'Administrador' : 'Funcionário';

  String get iniciais {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nome: json['nome']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        perfil: json['perfil']?.toString() ?? 'Funcionario',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'perfil': perfil,
      };
}
