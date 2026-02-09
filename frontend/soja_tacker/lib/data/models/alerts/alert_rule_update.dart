// lib/data/models/alerts/alert_rule_update.dart
class AlertRuleUpdate {
  final String? nome;
  final String? tipo;
  final Map<String, dynamic>? params;
  final bool? ativo;

  const AlertRuleUpdate({
    this.nome,
    this.tipo,
    this.params,
    this.ativo,
  });

  Map<String, dynamic> toJson() => {
        if (nome != null) 'nome': nome,
        if (tipo != null) 'tipo': tipo,
        if (params != null) 'params': params,
        if (ativo != null) 'ativo': ativo,
      };
}
