// lib/data/models/fx/fx_quote_read.dart
class FxQuoteRead {
  final int id;
  final int farmId;
  final int sourceId;
  final int? createdByUserId;
  final DateTime capturadoEm; // date-time
  final DateTime refMes; // date
  final double brlPerUsd;
  final String? observacao;

  const FxQuoteRead({
    required this.id,
    required this.farmId,
    required this.sourceId,
    required this.createdByUserId,
    required this.capturadoEm,
    required this.refMes,
    required this.brlPerUsd,
    required this.observacao,
  });

  factory FxQuoteRead.fromJson(Map<String, dynamic> json) {
    return FxQuoteRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      sourceId: (json['source_id'] as num).toInt(),
      createdByUserId: (json['created_by_user_id'] as num?)?.toInt(),
      capturadoEm: DateTime.parse(json['capturado_em'] as String),
      refMes: DateTime.parse(json['ref_mes'] as String),
      brlPerUsd: (json['brl_per_usd'] as num).toDouble(),
      observacao: (json['observacao'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farm_id': farmId,
        'source_id': sourceId,
        'created_by_user_id': createdByUserId,
        'capturado_em': capturadoEm.toIso8601String(),
        'ref_mes': refMes.toIso8601String().substring(0, 10),
        'brl_per_usd': brlPerUsd,
        'observacao': observacao,
      };
}
