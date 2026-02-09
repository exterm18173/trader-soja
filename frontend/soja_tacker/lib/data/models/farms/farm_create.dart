// lib/data/models/farms/farm_create.dart
class FarmCreate {
  final String nome;

  const FarmCreate({required this.nome});

  Map<String, dynamic> toJson() => {
        'nome': nome,
      };
}
