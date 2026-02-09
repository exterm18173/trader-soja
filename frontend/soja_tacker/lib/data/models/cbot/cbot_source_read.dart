// lib/data/models/cbot/cbot_source_read.dart
class CbotSourceRead {
  final int id;
  final String nome;
  final bool ativo;

  const CbotSourceRead({
    required this.id,
    required this.nome,
    required this.ativo,
  });

  factory CbotSourceRead.fromJson(Map<String, dynamic> json) {
    return CbotSourceRead(
      id: (json['id'] as num).toInt(),
      nome: (json['nome'] as String),
      ativo: (json['ativo'] as bool),
    );
  }
}
