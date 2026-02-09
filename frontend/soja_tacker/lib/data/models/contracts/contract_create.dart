class ContractCreate {
  final String produto; // default "SOJA" na API
  final String tipoPrecificacao;

  final double volumeInputValue;
  final String volumeInputUnit;
  final double volumeTotalTon;

  final DateTime dataEntrega; // date

  final double? precoFixoBrlValue;
  final String? precoFixoBrlUnit;

  // ✅ NOVO: frete
  final double? freteBrlTotal;
  final double? freteBrlPerTon;
  final String? freteObs;

  final String? observacao;

  const ContractCreate({
    this.produto = 'SOJA',
    required this.tipoPrecificacao,
    required this.volumeInputValue,
    required this.volumeInputUnit,
    required this.volumeTotalTon,
    required this.dataEntrega,
    this.precoFixoBrlValue,
    this.precoFixoBrlUnit,
    this.freteBrlTotal,
    this.freteBrlPerTon,
    this.freteObs,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        'produto': produto,
        'tipo_precificacao': tipoPrecificacao,
        'volume_input_value': volumeInputValue,
        'volume_input_unit': volumeInputUnit,
        'volume_total_ton': volumeTotalTon,
        'data_entrega': dataEntrega.toIso8601String().substring(0, 10),
        'preco_fixo_brl_value': precoFixoBrlValue,
        'preco_fixo_brl_unit': precoFixoBrlUnit,

        // ✅ NOVO: frete
        'frete_brl_total': freteBrlTotal,
        'frete_brl_per_ton': freteBrlPerTon,
        'frete_obs': freteObs,

        'observacao': observacao,
      };
}
