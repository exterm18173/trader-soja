// lib/data/models/fx/fx_manual_point_read.dart
class FxManualPointRead {
  final int id;
  final int farmId;
  final int sourceId;
  final int createdByUserId;
  final DateTime capturedAt; // date-time
  final DateTime refMes; // date (usa o 1º dia do mês)
  final double fx;

  const FxManualPointRead({
    required this.id,
    required this.farmId,
    required this.sourceId,
    required this.createdByUserId,
    required this.capturedAt,
    required this.refMes,
    required this.fx,
  });

  factory FxManualPointRead.fromJson(Map<String, dynamic> json) {
    return FxManualPointRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      sourceId: (json['source_id'] as num).toInt(),
      createdByUserId: (json['created_by_user_id'] as num).toInt(),
      capturedAt: DateTime.parse(json['captured_at'] as String),
      refMes: DateTime.parse(json['ref_mes'] as String),
      fx: (json['fx'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farm_id': farmId,
        'source_id': sourceId,
        'created_by_user_id': createdByUserId,
        'captured_at': capturedAt.toIso8601String(),
        'ref_mes': refMes.toIso8601String().substring(0, 10),
        'fx': fx,
      };
}
