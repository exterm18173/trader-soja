class ContractUpdate {
  final String? status;
  final DateTime? dataEntrega;

  final double? volumeInputValue;
  final String? volumeInputUnit;
  final double? volumeTotalTon;

  final double? precoFixoBrlValue;
  final String? precoFixoBrlUnit;

  // ✅ NOVO: frete
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
        'status': status,
        'data_entrega': dataEntrega?.toIso8601String().substring(0, 10),
        'volume_input_value': volumeInputValue,
        'volume_input_unit': volumeInputUnit,
        'volume_total_ton': volumeTotalTon,
        'preco_fixo_brl_value': precoFixoBrlValue,
        'preco_fixo_brl_unit': precoFixoBrlUnit,

        // ✅ NOVO: frete
        'frete_brl_total': freteBrlTotal,
        'frete_brl_per_ton': freteBrlPerTon,
        'frete_obs': freteObs,

        'observacao': observacao,
      };
}
