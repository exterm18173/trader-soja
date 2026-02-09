// lib/data/models/fx/fx_manual_point_create.dart
class FxManualPointCreate {
  final int sourceId;
  final DateTime capturedAt;
  final DateTime refMes; // date
  final double fx;

  const FxManualPointCreate({
    required this.sourceId,
    required this.capturedAt,
    required this.refMes,
    required this.fx,
  });

  Map<String, dynamic> toJson() => {
        'source_id': sourceId,
        'captured_at': capturedAt.toIso8601String(),
        'ref_mes': refMes.toIso8601String().substring(0, 10),
        'fx': fx,
      };
}
