import 'package:intl/intl.dart';
import '../../models/currency.dart';

class CurrencyFormatter {
  final Currency currency;

  CurrencyFormatter(this.currency);

  // 1. Standard Format: $1,234.56
  String formatNumber(double amount, String locale) {
    final format = NumberFormat.decimalPattern(locale);
    return format.format(amount);
  }

  // 2. Compact Format: $1.2K or $2.5M
  String formatCompact(double amount, String locale) {
    final format = NumberFormat.compact(locale: locale);
    return format.format(amount);
  }

  // 3. Simple Display: No decimals for whole numbers
  String formatDisplay(double amount, String locale) {
    if (amount == amount.toInt()) {
      return NumberFormat.decimalPattern(locale).format(amount);
    }
    return NumberFormat("#,##0.00", locale).format(amount);
  }
  
}