// lib/data/models/fx/fx_spot_tick_read.dart
class FxSpotTickRead {
  final int id;
  final int farmId;
  final DateTime ts;
  final double price;
  final String source;

  const FxSpotTickRead({
    required this.id,
    required this.farmId,
    required this.ts,
    required this.price,
    required this.source,
  });

  factory FxSpotTickRead.fromJson(Map<String, dynamic> json) {
    return FxSpotTickRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      ts: DateTime.parse(json['ts'] as String),
      price: (json['price'] as num).toDouble(),
      source: (json['source'] as String).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farm_id': farmId,
        'ts': ts.toIso8601String(),
        'price': price,
        'source': source,
      };
}
