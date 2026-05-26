import 'package:intl/intl.dart';
import '../../models/currency.dart';

class CurrencyFormatter {
  final Currency currency;

  CurrencyFormatter(this.currency);

  String get _spacedSymbol => '${currency.symbol}\u00A0';

  /// Standard Full Format: e.g., KSh 1,234.56 or $1,234.56
  String formatDisplay(double amount, String locale) {
    final format = NumberFormat.currency(
      locale: locale,
      name: currency.code,   
      symbol: _spacedSymbol, 

      decimalDigits: _getDecimalDigits(), 
    );
    return format.format(amount);
  }

  /// Compact Format: e.g., KSh 1.2M or 1.2M $ depending on locale rules
  String formatCompact(double amount, String locale) {
    final format = NumberFormat.compactCurrency(
      locale: locale,
      symbol:_spacedSymbol,
      name: currency.code,
      decimalDigits: 1, // 1.2K instead of 1.23K
    );
    return format.format(amount);
  }

  int _getDecimalDigits() {
    // Optional safety check for zero-decimal currencies if your app supports them
    final zeroDecimalCurrencies = {'JPY', 'KRW', 'CLP', 'VND', 'BIF', 'DJF', 'GNF', 'KMF', 'RWF', 'XAF', 'XOF', 'XPF'};
    return zeroDecimalCurrencies.contains(currency.code.toUpperCase()) ? 0 : 2;
  }
}