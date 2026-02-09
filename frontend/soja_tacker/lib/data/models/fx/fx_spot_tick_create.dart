// lib/data/models/fx/fx_spot_tick_create.dart
class FxSpotTickCreate {
  final DateTime ts;
  final double price;
  final String source; // default "B3" no backend

  const FxSpotTickCreate({
    required this.ts,
    required this.price,
    this.source = 'B3',
  });

  Map<String, dynamic> toJson() => {
        'ts': ts.toIso8601String(),
        'price': price,
        'source': source,
      };
}
