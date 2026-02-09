// lib/data/models/cbot/cbot_source_create.dart
class CbotSourceCreate {
  final String nome;
  final bool ativo;

  const CbotSourceCreate({
    required this.nome,
    this.ativo = true,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'ativo': ativo,
      };
}
