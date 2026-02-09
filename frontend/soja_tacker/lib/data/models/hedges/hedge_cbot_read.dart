// lib/data/models/hedges/hedge_cbot_read.dart
class HedgeCbotRead {
  final int id;
  final int contractId;
  final int executedByUserId;

  final DateTime executadoEm;
  final double volumeInputValue;
  final String volumeInputUnit;
  final double volumeTon;
  final double cbotUsdPerBu;

  final DateTime? refMes;
  final String? symbol;
  final String? observacao;

  const HedgeCbotRead({
    required this.id,
    required this.contractId,
    required this.executedByUserId,
    required this.executadoEm,
    required this.volumeInputValue,
    required this.volumeInputUnit,
    required this.volumeTon,
    required this.cbotUsdPerBu,
    required this.refMes,
    required this.symbol,
    required this.observacao,
  });

  factory HedgeCbotRead.fromJson(Map<String, dynamic> json) {
    return HedgeCbotRead(
      id: (json['id'] as num).toInt(),
      contractId: (json['contract_id'] as num).toInt(),
      executedByUserId: (json['executed_by_user_id'] as num).toInt(),
      executadoEm: DateTime.parse(json['executado_em'] as String),
      volumeInputValue: (json['volume_input_value'] as num).toDouble(),
      volumeInputUnit: (json['volume_input_unit'] as String),
      volumeTon: (json['volume_ton'] as num).toDouble(),
      cbotUsdPerBu: (json['cbot_usd_per_bu'] as num).toDouble(),
      refMes: json['ref_mes'] == null ? null : DateTime.parse(json['ref_mes'] as String),
      symbol: json['symbol'] as String?,
      observacao: json['observacao'] as String?,
    );
  }
}
