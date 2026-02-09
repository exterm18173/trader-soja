// lib/data/models/alerts/alert_event_read.dart
class AlertEventRead {
  final int id;
  final int farmId;
  final int? ruleId;

  final DateTime triggeredAt; // date-time
  final String severity;
  final String title;
  final String message;
  final bool read;

  const AlertEventRead({
    required this.id,
    required this.farmId,
    required this.ruleId,
    required this.triggeredAt,
    required this.severity,
    required this.title,
    required this.message,
    required this.read,
  });

  factory AlertEventRead.fromJson(Map<String, dynamic> json) {
    return AlertEventRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      ruleId: json['rule_id'] == null ? null : (json['rule_id'] as num).toInt(),
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      severity: (json['severity'] as String),
      title: (json['title'] as String),
      message: (json['message'] as String),
      read: (json['read'] as bool),
    );
  }
}
