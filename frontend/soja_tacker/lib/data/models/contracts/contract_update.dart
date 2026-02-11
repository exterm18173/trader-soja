class ContractUpdate {
  final String? status;
  final DateTime? dataEntrega;

  final double? volumeInputValue;
  final String? volumeInputUnit;
  final double? volumeTotalTon;

  final double? precoFixoBrlValue;
  final String? precoFixoBrlUnit;

  // ✅ frete
  final double? freteBrlTotal;
  final double? freteBrlPerTon;
  final String? freteObs;

  final String? observacao;

  const ContractUpdate({
    this.status,
    this.dataEntrega,
    this.volumeInputValue,
    this.volumeInputUnit,
    this.volumeTotalTon,
    this.precoFixoBrlValue,
    this.precoFixoBrlUnit,
    this.freteBrlTotal,
    this.freteBrlPerTon,
    this.freteObs,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        if (status != null) 'status': status,
        if (dataEntrega != null) 'data_entrega': dataEntrega!.toIso8601String().substring(0, 10),

        if (volumeInputValue != null) 'volume_input_value': volumeInputValue,
        if (volumeInputUnit != null) 'volume_input_unit': volumeInputUnit,
        if (volumeTotalTon != null) 'volume_total_ton': volumeTotalTon,

        if (precoFixoBrlValue != null) 'preco_fixo_brl_value': precoFixoBrlValue,
        if (precoFixoBrlUnit != null) 'preco_fixo_brl_unit': precoFixoBrlUnit,

        // ✅ frete
        if (freteBrlTotal != null) 'frete_brl_total': freteBrlTotal,
        if (freteBrlPerTon != null) 'frete_brl_per_ton': freteBrlPerTon,
        if (freteObs != null) 'frete_obs': freteObs,

        if (observacao != null) 'observacao': observacao,
      };
}
