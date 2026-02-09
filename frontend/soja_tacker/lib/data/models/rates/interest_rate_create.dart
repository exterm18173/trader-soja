// lib/data/models/rates/interest_rate_create.dart
class InterestRateCreate {
  final DateTime rateDate;
  final double cdiAnnual;
  final double sofrAnnual;

  const InterestRateCreate({
    required this.rateDate,
    required this.cdiAnnual,
    required this.sofrAnnual,
  });

  Map<String, dynamic> toJson() => {
        'rate_date': rateDate.toIso8601String().substring(0, 10),
        'cdi_annual': cdiAnnual,
        'sofr_annual': sofrAnnual,
      };
}
