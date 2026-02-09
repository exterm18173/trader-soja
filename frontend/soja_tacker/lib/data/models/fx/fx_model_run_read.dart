// lib/data/models/fx/fx_model_run_read.dart
class FxModelRunRead {
  final int id;
  final int farmId;
  final DateTime asOfTs; // date-time
  final double spotUsdbrl;
  final double cdiAnnual;
  final double sofrAnnual;
  final double offsetValue;
  final double couponAnnual;
  final double descontoPct;
  final String modelVersion;
  final String source;

  const FxModelRunRead({
    required this.id,
    required this.farmId,
    required this.asOfTs,
    required this.spotUsdbrl,
    required this.cdiAnnual,
    required this.sofrAnnual,
    required this.offsetValue,
    required this.couponAnnual,
    required this.descontoPct,
    required this.modelVersion,
    required this.source,
  });

  factory FxModelRunRead.fromJson(Map<String, dynamic> json) {
    return FxModelRunRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      asOfTs: DateTime.parse(json['as_of_ts'] as String),
      spotUsdbrl: (json['spot_usdbrl'] as num).toDouble(),
      cdiAnnual: (json['cdi_annual'] as num).toDouble(),
      sofrAnnual: (json['sofr_annual'] as num).toDouble(),
      offsetValue: (json['offset_value'] as num).toDouble(),
      couponAnnual: (json['coupon_annual'] as num).toDouble(),
      descontoPct: (json['desconto_pct'] as num).toDouble(),
      modelVersion: (json['model_version'] as String),
      source: (json['source'] as String),
    );
  }
}
