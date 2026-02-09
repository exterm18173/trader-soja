// lib/data/models/alerts/alert_rule_read.dart
class AlertRuleRead {
  final int id;
  final int farmId;
  final int createdByUserId;
  final bool ativo;

  final String tipo;
  final String nome;

  final String paramsJson;
  final Map<String, dynamic> params;

  const AlertRuleRead({
    required this.id,
    required this.farmId,
    required this.createdByUserId,
    required this.ativo,
    required this.tipo,
    required this.nome,
    required this.paramsJson,
    required this.params,
  });

  factory AlertRuleRead.fromJson(Map<String, dynamic> json) {
    return AlertRuleRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      createdByUserId: (json['created_by_user_id'] as num).toInt(),
      ativo: (json['ativo'] as bool),
      tipo: (json['tipo'] as String),
      nome: (json['nome'] as String),
      paramsJson: (json['params_json'] as String),
      params: (json['params'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    );
  }
}
