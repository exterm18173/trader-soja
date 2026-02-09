class ContractRead {
  final int id;
  final int farmId;
  final int createdByUserId;

  final String produto;
  final String tipoPrecificacao;

  final double volumeInputValue;
  final String volumeInputUnit;
  final double volumeTotalTon;

  final DateTime dataEntrega;
  final String status;

  final double? precoFixoBrlValue;
  final String? precoFixoBrlUnit;

  // ✅ NOVO: frete
  final double? freteBrlTotal;
  final double? freteBrlPerTon;
  final String? freteObs;

  final String? observacao;

  const ContractRead({
    required this.id,
    required this.farmId,
    required this.createdByUserId,
    required this.produto,
    required this.tipoPrecificacao,
    required this.volumeInputValue,
    required this.volumeInputUnit,
    required this.volumeTotalTon,
    required this.dataEntrega,
    required this.status,
    required this.precoFixoBrlValue,
    required this.precoFixoBrlUnit,
    required this.freteBrlTotal,
    required this.freteBrlPerTon,
    required this.freteObs,
    required this.observacao,
  });

  factory ContractRead.fromJson(Map<String, dynamic> json) {
    return ContractRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      createdByUserId: (json['created_by_user_id'] as num).toInt(),
      produto: (json['produto'] as String),
      tipoPrecificacao: (json['tipo_precificacao'] as String),
      volumeInputValue: (json['volume_input_value'] as num).toDouble(),
      volumeInputUnit: (json['volume_input_unit'] as String),
      volumeTotalTon: (json['volume_total_ton'] as num).toDouble(),
      dataEntrega: DateTime.parse(json['data_entrega'] as String),
      status: (json['status'] as String),
      precoFixoBrlValue: (json['preco_fixo_brl_value'] as num?)?.toDouble(),
      precoFixoBrlUnit: (json['preco_fixo_brl_unit'] as String?),

      // ✅ NOVO: frete
      freteBrlTotal: (json['frete_brl_total'] as num?)?.toDouble(),
      freteBrlPerTon: (json['frete_brl_per_ton'] as num?)?.toDouble(),
      freteObs: (json['frete_obs'] as String?),

      observacao: (json['observacao'] as String?),
    );
  }
}
