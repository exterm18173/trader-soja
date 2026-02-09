// lib/data/models/farms/farm_update.dart
class FarmUpdate {
  final String? nome;
  final bool? ativo;

  const FarmUpdate({
    this.nome,
    this.ativo,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (nome != null) map['nome'] = nome;
    if (ativo != null) map['ativo'] = ativo;
    return map;
  }
}
