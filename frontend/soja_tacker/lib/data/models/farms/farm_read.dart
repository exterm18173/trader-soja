// lib/data/models/farms/farm_read.dart
class FarmRead {
  final int id;
  final String nome;
  final bool ativo;

  const FarmRead({
    required this.id,
    required this.nome,
    required this.ativo,
  });

  factory FarmRead.fromJson(Map<String, dynamic> json) {
    return FarmRead(
      id: (json['id'] as num).toInt(),
      nome: (json['nome'] ?? '').toString(),
      ativo: (json['ativo'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'ativo': ativo,
      };
}
