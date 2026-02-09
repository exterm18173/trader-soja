// lib/data/models/rates/interest_rate_upsert.dart
class InterestRateUpsert {
  final double cdiAnnual;
  final double sofrAnnual;

  const InterestRateUpsert({
    required this.cdiAnnual,
    required this.sofrAnnual,
  });

  Map<String, dynamic> toJson() => {
        'cdi_annual': cdiAnnual,
        'sofr_annual': sofrAnnual,
      };
}
