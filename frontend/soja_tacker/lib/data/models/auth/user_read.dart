// lib/data/models/auth/user_read.dart
class UserRead {
  final int id;
  final String nome;
  final String email;
  final bool ativo;

  const UserRead({
    required this.id,
    required this.nome,
    required this.email,
    required this.ativo,
  });

  factory UserRead.fromJson(Map<String, dynamic> json) {
    return UserRead(
      id: (json['id'] as num).toInt(),
      nome: (json['nome'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      ativo: (json['ativo'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'ativo': ativo,
      };
}
