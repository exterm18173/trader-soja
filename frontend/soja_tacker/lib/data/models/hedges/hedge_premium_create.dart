// lib/data/models/hedges/hedge_premium_create.dart
class HedgePremiumCreate {
  final DateTime executadoEm; // date-time
  final double volumeInputValue;
  final String volumeInputUnit;
  final double volumeTon;

  final double premiumValue;
  final String premiumUnit;

  final String? baseLocal;
  final String? observacao;

  const HedgePremiumCreate({
    required this.executadoEm,
    required this.volumeInputValue,
    required this.volumeInputUnit,
    required this.volumeTon,
    required this.premiumValue,
    required this.premiumUnit,
    this.baseLocal,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        'executado_em': executadoEm.toIso8601String(),
        'volume_input_value': volumeInputValue,
        'volume_input_unit': volumeInputUnit,
        'volume_ton': volumeTon,
        'premium_value': premiumValue,
        'premium_unit': premiumUnit,
        'base_local': baseLocal,
        'observacao': observacao,
      };
}
