// lib/data/models/fx/fx_source_read.dart
class FxSourceRead {
  final int id;
  final String nome;
  final bool ativo;

  const FxSourceRead({
    required this.id,
    required this.nome,
    required this.ativo,
  });

  factory FxSourceRead.fromJson(Map<String, dynamic> json) {
    return FxSourceRead(
      id: (json['id'] as num).toInt(),
      nome: (json['nome'] as String).toString(),
      ativo: (json['ativo'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'ativo': ativo,
      };
}
