// lib/data/models/rates/interest_rate_update.dart
class InterestRateUpdate {
  final double? cdiAnnual;
  final double? sofrAnnual;

  const InterestRateUpdate({
    this.cdiAnnual,
    this.sofrAnnual,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (cdiAnnual != null) map['cdi_annual'] = cdiAnnual;
    if (sofrAnnual != null) map['sofr_annual'] = sofrAnnual;
    return map;
  }
}
