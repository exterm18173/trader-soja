// lib/data/models/fx/fx_quote_create.dart
class FxQuoteCreate {
  final int sourceId;
  final DateTime capturadoEm;
  final DateTime refMes;
  final double brlPerUsd;
  final String? observacao;

  const FxQuoteCreate({
    required this.sourceId,
    required this.capturadoEm,
    required this.refMes,
    required this.brlPerUsd,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        'source_id': sourceId,
        'capturado_em': capturadoEm.toIso8601String(),
        'ref_mes': refMes.toIso8601String().substring(0, 10),
        'brl_per_usd': brlPerUsd,
        'observacao': observacao,
      };
}
