// lib/data/models/hedges/hedge_premium_read.dart
class HedgePremiumRead {
  final int id;
  final int contractId;
  final int executedByUserId;

  final DateTime executadoEm;
  final double volumeInputValue;
  final String volumeInputUnit;
  final double volumeTon;

  final double premiumValue;
  final String premiumUnit;

  final String? baseLocal;
  final String? observacao;

  const HedgePremiumRead({
    required this.id,
    required this.contractId,
    required this.executedByUserId,
    required this.executadoEm,
    required this.volumeInputValue,
    required this.volumeInputUnit,
    required this.volumeTon,
    required this.premiumValue,
    required this.premiumUnit,
    required this.baseLocal,
    required this.observacao,
  });

  factory HedgePremiumRead.fromJson(Map<String, dynamic> json) {
    return HedgePremiumRead(
      id: (json['id'] as num).toInt(),
      contractId: (json['contract_id'] as num).toInt(),
      executedByUserId: (json['executed_by_user_id'] as num).toInt(),
      executadoEm: DateTime.parse(json['executado_em'] as String),
      volumeInputValue: (json['volume_input_value'] as num).toDouble(),
      volumeInputUnit: (json['volume_input_unit'] as String),
      volumeTon: (json['volume_ton'] as num).toDouble(),
      premiumValue: (json['premium_value'] as num).toDouble(),
      premiumUnit: (json['premium_unit'] as String),
      baseLocal: json['base_local'] as String?,
      observacao: json['observacao'] as String?,
    );
  }
}
