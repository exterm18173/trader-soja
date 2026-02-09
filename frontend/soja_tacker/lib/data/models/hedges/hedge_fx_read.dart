class HedgeFxRead {
  final int id;
  final int contractId;
  final int executedByUserId;

  final DateTime executadoEm;

  // ✅ NOVO
  final double volumeTon;

  final double usdAmount;
  final double brlPerUsd;

  final DateTime? refMes;
  final String tipo;
  final String? observacao;

  const HedgeFxRead({
    required this.id,
    required this.contractId,
    required this.executedByUserId,
    required this.executadoEm,
    required this.volumeTon,
    required this.usdAmount,
    required this.brlPerUsd,
    required this.refMes,
    required this.tipo,
    required this.observacao,
  });

  factory HedgeFxRead.fromJson(Map<String, dynamic> json) {
    return HedgeFxRead(
      id: (json['id'] as num).toInt(),
      contractId: (json['contract_id'] as num).toInt(),
      executedByUserId: (json['executed_by_user_id'] as num).toInt(),
      executadoEm: DateTime.parse(json['executado_em'] as String),

      volumeTon: (json['volume_ton'] as num).toDouble(), // ✅ NOVO

      usdAmount: (json['usd_amount'] as num).toDouble(),
      brlPerUsd: (json['brl_per_usd'] as num).toDouble(),
      refMes: json['ref_mes'] == null ? null : DateTime.parse(json['ref_mes'] as String),
      tipo: (json['tipo'] as String),
      observacao: json['observacao'] as String?,
    );
  }
}
