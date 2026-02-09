// lib/data/models/cbot/cbot_quote_read.dart
class CbotQuoteRead {
  final int id;
  final int farmId;
  final int sourceId;
  final DateTime capturadoEm; // date-time
  final String symbol;
  final double priceUsdPerBu;

  const CbotQuoteRead({
    required this.id,
    required this.farmId,
    required this.sourceId,
    required this.capturadoEm,
    required this.symbol,
    required this.priceUsdPerBu,
  });

  factory CbotQuoteRead.fromJson(Map<String, dynamic> json) {
    return CbotQuoteRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      sourceId: (json['source_id'] as num).toInt(),
      capturadoEm: DateTime.parse(json['capturado_em'] as String),
      symbol: (json['symbol'] as String),
      priceUsdPerBu: (json['price_usd_per_bu'] as num).toDouble(),
    );
  }
}
