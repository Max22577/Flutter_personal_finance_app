import 'package:intl/intl.dart';
import '../../models/currency.dart';


class CurrencyFormatter {
  final Currency currency;

  CurrencyFormatter(this.currency);

  // 1. Standard Format: $1,234.56
  String format(double amount) {
    final format = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: currency.decimalDigits,
      locale: currency.locale,
    );
    return format.format(amount);
  }

  // 2. Compact Format: $1.2K or $2.5M
  String formatCompact(double amount) {
    final format = NumberFormat.compactCurrency(
      symbol: currency.symbol,
      locale: currency.locale,
    );
    return format.format(amount);
  }

  // 3. Simple Display: No decimals for whole numbers
  String formatDisplay(double amount) {
    return amount == amount.toInt() 
      ? NumberFormat.currency(symbol: currency.symbol, decimalDigits: 0, locale: currency.locale).format(amount)
      : format(amount);
  }
}