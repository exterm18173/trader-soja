// lib/data/models/fx/fx_quote_check_read.dart
class FxQuoteCheckRead {
  final int id;
  final int quoteId;
  final int farmId;
  final int? manualPointId;
  final int modelRunId;
  final int modelPointId;
  final DateTime refMes;
  final double fxManual;
  final double fxModel;
  final double deltaAbs;
  final double deltaPct;

  const FxQuoteCheckRead({
    required this.id,
    required this.quoteId,
    required this.farmId,
    required this.manualPointId,
    required this.modelRunId,
    required this.modelPointId,
    required this.refMes,
    required this.fxManual,
    required this.fxModel,
    required this.deltaAbs,
    required this.deltaPct,
  });

  factory FxQuoteCheckRead.fromJson(Map<String, dynamic> json) {
    return FxQuoteCheckRead(
      id: (json['id'] as num).toInt(),
      quoteId: (json['quote_id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      manualPointId: (json['manual_point_id'] as num?)?.toInt(),
      modelRunId: (json['model_run_id'] as num).toInt(),
      modelPointId: (json['model_point_id'] as num).toInt(),
      refMes: DateTime.parse(json['ref_mes'] as String),
      fxManual: (json['fx_manual'] as num).toDouble(),
      fxModel: (json['fx_model'] as num).toDouble(),
      deltaAbs: (json['delta_abs'] as num).toDouble(),
      deltaPct: (json['delta_pct'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quote_id': quoteId,
        'farm_id': farmId,
        'manual_point_id': manualPointId,
        'model_run_id': modelRunId,
        'model_point_id': modelPointId,
        'ref_mes': refMes.toIso8601String().substring(0, 10),
        'fx_manual': fxManual,
        'fx_model': fxModel,
        'delta_abs': deltaAbs,
        'delta_pct': deltaPct,
      };
}
