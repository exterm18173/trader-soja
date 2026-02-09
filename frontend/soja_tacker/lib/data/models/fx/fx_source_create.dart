// lib/data/models/fx/fx_source_create.dart
class FxSourceCreate {
  final String nome;
  final bool ativo;

  const FxSourceCreate({
    required this.nome,
    this.ativo = true,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'ativo': ativo,
      };
}
