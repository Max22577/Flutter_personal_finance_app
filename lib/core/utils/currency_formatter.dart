import 'package:intl/intl.dart';
import '../../models/currency.dart';

class CurrencyFormatter {
  final Currency currency;

  CurrencyFormatter(this.currency);

  // Standard Format: $1,234.56
  String formatNumber(double amount, String locale) {
    final format = NumberFormat.currency(
      locale: locale,
      symbol: currency.symbol, 
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  // Compact Format: $1.2K or $2.5M
  String formatDisplay(double amount, String locale) {
    final symbol = currency.symbol;
    if (amount == amount.toInt()) {
      // Formats as $1,234
      return NumberFormat.currency(
        locale: locale, 
        symbol: symbol, 
        decimalDigits: 0
      ).format(amount);
    }
    // Formats as $1,234.56
    return NumberFormat.currency(
      locale: locale, 
      symbol: symbol, 
      decimalDigits: 2
    ).format(amount);
  }

  String formatCompact(double amount, String locale) {
    final format = NumberFormat.compact(locale: locale);
    return '${currency.symbol}${format.format(amount)}';
  }
 
  
}