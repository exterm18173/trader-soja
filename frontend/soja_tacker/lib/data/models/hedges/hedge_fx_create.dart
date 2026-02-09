class HedgeFxCreate {
  final DateTime executadoEm; // date-time

  // ✅ NOVO
  final double volumeTon;

  final double usdAmount;
  final double brlPerUsd;

  final DateTime? refMes; // date (opcional)
  final String tipo; // default "CURVA_SCRIPT"
  final String? observacao;

  const HedgeFxCreate({
    required this.executadoEm,
    required this.volumeTon,
    required this.usdAmount,
    required this.brlPerUsd,
    this.refMes,
    this.tipo = 'CURVA_SCRIPT',
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        'executado_em': executadoEm.toIso8601String(),
        'volume_ton': volumeTon, // ✅ NOVO
        'usd_amount': usdAmount,
        'brl_per_usd': brlPerUsd,
        'ref_mes': refMes?.toIso8601String().substring(0, 10),
        'tipo': tipo,
        'observacao': observacao,
      };
}
