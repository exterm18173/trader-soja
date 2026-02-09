// lib/data/models/hedges/hedge_cbot_create.dart
class HedgeCbotCreate {
  final DateTime executadoEm; // date-time
  final double volumeInputValue;
  final String volumeInputUnit;
  final double volumeTon;
  final double cbotUsdPerBu;

  final DateTime? refMes; // date (opcional)
  final String? symbol; // opcional
  final String? observacao; // opcional

  const HedgeCbotCreate({
    required this.executadoEm,
    required this.volumeInputValue,
    required this.volumeInputUnit,
    required this.volumeTon,
    required this.cbotUsdPerBu,
    this.refMes,
    this.symbol,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        'executado_em': executadoEm.toIso8601String(),
        'volume_input_value': volumeInputValue,
        'volume_input_unit': volumeInputUnit,
        'volume_ton': volumeTon,
        'cbot_usd_per_bu': cbotUsdPerBu,
        'ref_mes': refMes?.toIso8601String().substring(0, 10),
        'symbol': symbol,
        'observacao': observacao,
      };
}
