// lib/data/models/fx/fx_manual_point_update.dart
class FxManualPointUpdate {
  final DateTime? capturedAt;
  final DateTime? refMes;
  final double? fx;

  const FxManualPointUpdate({
    this.capturedAt,
    this.refMes,
    this.fx,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (capturedAt != null) map['captured_at'] = capturedAt!.toIso8601String();
    if (refMes != null) map['ref_mes'] = refMes!.toIso8601String().substring(0, 10);
    if (fx != null) map['fx'] = fx;
    return map;
  }
}
