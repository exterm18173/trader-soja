// lib/data/models/alerts/alert_rule_create.dart
class AlertRuleCreate {
  final String nome;
  final String tipo;
  final Map<String, dynamic>? params;
  final bool ativo;

  const AlertRuleCreate({
    required this.nome,
    required this.tipo,
    this.params,
    this.ativo = true,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'tipo': tipo,
        if (params != null) 'params': params,
        'ativo': ativo,
      };
}
