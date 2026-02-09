// lib/data/models/rates/interest_rate_read.dart
class InterestRateRead {
  final int id;
  final int farmId;
  final int createdByUserId;
  final DateTime rateDate;
  final double cdiAnnual;
  final double sofrAnnual;

  const InterestRateRead({
    required this.id,
    required this.farmId,
    required this.createdByUserId,
    required this.rateDate,
    required this.cdiAnnual,
    required this.sofrAnnual,
  });

  factory InterestRateRead.fromJson(Map<String, dynamic> json) {
    return InterestRateRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      createdByUserId: (json['created_by_user_id'] as num).toInt(),
      rateDate: DateTime.parse(json['rate_date'] as String),
      cdiAnnual: (json['cdi_annual'] as num).toDouble(),
      sofrAnnual: (json['sofr_annual'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farm_id': farmId,
        'created_by_user_id': createdByUserId,
        'rate_date': rateDate.toIso8601String().substring(0, 10),
        'cdi_annual': cdiAnnual,
        'sofr_annual': sofrAnnual,
      };
}
