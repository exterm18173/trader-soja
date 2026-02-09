// lib/data/models/alerts/alert_event_update.dart
class AlertEventUpdate {
  final bool? read;

  const AlertEventUpdate({this.read});

  Map<String, dynamic> toJson() => {
        if (read != null) 'read': read,
      };
}
