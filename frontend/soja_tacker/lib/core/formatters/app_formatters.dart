import 'package:intl/intl.dart';

/// Formatadores padrão para números / moedas.
///
/// - USD: en_US (1,234.56)
/// - BRL: pt_BR (1.234,56)
/// - Inteiros e decimais com milhar
/// - Percentual
/// - Preços por unidade (ex: USD/bu, USD/saca, BRL/saca)
class AppFormatters {
  AppFormatters._();

  // ====== Currency ======
  static final NumberFormat _usd = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'US\$',
    decimalDigits: 2,
  );

  static final NumberFormat _brl = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  // ====== Numbers ======
  static final NumberFormat _intPt = NumberFormat.decimalPattern('pt_BR');
  static final NumberFormat _intUs = NumberFormat.decimalPattern('en_US');

  /// Decimal pt_BR com casas configuráveis (ex: 1.234,5678)
  static NumberFormat _decPt(int decimals) => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: '',
        decimalDigits: decimals,
      );

  /// Decimal en_US com casas configuráveis (ex: 1,234.5678)
  static NumberFormat _decUs(int decimals) => NumberFormat.currency(
        locale: 'en_US',
        symbol: '',
        decimalDigits: decimals,
      );

  // ====== Helpers (null-safe) ======
  static String usd(double? v, {int decimals = 2}) {
    if (v == null) return '-';
    if (decimals == 2) return _usd.format(v);
    // moeda com casas custom:
    final f = NumberFormat.currency(locale: 'en_US', symbol: 'US\$', decimalDigits: decimals);
    return f.format(v);
  }

  static String brl(double? v, {int decimals = 2}) {
    if (v == null) return '-';
    if (decimals == 2) return _brl.format(v);
    final f = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: decimals);
    return f.format(v);
  }

  /// Inteiro com separador de milhar.
  /// Por padrão uso pt_BR (1.234.567). Se quiser en_US, passe us=true.
  static String intN(num? v, {bool us = false}) {
    if (v == null) return '-';
    return (us ? _intUs : _intPt).format(v.round());
  }

  /// Decimal sem símbolo de moeda, com separador de milhar.
  /// Ex: 1.234,5678 (pt_BR) ou 1,234.5678 (en_US)
  static String dec(double? v, {int decimals = 2, bool us = false}) {
    if (v == null) return '-';
    return (us ? _decUs(decimals) : _decPt(decimals)).format(v).trim();
  }

  /// Percentual (v = 0.123 -> 12,3%)
  static String pct(double? v, {int decimals = 1}) {
    if (v == null) return '-';
    final p = v * 100.0;
    // percentual costuma ficar mais “BR”
    final f = NumberFormat.decimalPattern('pt_BR')..minimumFractionDigits = decimals..maximumFractionDigits = decimals;
    return '${f.format(p)}%';
  }

  // ====== Domain helpers ======
  /// Preço em USD por bushel (CBOT).
  /// Normalmente 2 casas é suficiente, mas deixei configurável.
  static String usdPerBushel(double? v, {int decimals = 2}) {
    if (v == null) return '-';
    return '${dec(v, decimals: decimals, us: true)} USD/bu';
  }

  /// Preço em USD por saca (normalmente você quer “US$ 12.34” e não “USD/saca”)
  static String usdPerSaca(double? v, {int decimals = 2}) => usd(v, decimals: decimals);

  /// Preço em BRL por saca
  static String brlPerSaca(double? v, {int decimals = 2}) => brl(v, decimals: decimals);

  /// Toneladas com 2 casas (pt_BR)
  static String ton(double? v, {int decimals = 2}) => dec(v, decimals: decimals, us: false);

  /// Sacas geralmente é inteiro
  static String sacas(double? v) => intN(v ?? 0, us: false);
}
