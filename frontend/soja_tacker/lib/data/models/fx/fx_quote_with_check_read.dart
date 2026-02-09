// lib/data/models/fx/fx_quote_with_check_read.dart
import 'fx_quote_read.dart';
import 'fx_quote_check_read.dart';

class FxQuoteWithCheckRead {
  final FxQuoteRead quote;
  final FxQuoteCheckRead check;

  const FxQuoteWithCheckRead({
    required this.quote,
    required this.check,
  });

  factory FxQuoteWithCheckRead.fromJson(Map<String, dynamic> json) {
    return FxQuoteWithCheckRead(
      quote: FxQuoteRead.fromJson(json['quote'] as Map<String, dynamic>),
      check: FxQuoteCheckRead.fromJson(json['check'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'quote': quote.toJson(),
        'check': check.toJson(),
      };
}
