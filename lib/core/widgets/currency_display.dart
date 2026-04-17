import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class CurrencyDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool compact;
  final Color? positiveColor;
  final Color? negativeColor;
  final bool showSign;
  final bool isExpense;

  const CurrencyDisplay({
    super.key,
    required this.amount,
    this.style,
    this.compact = false,
    this.positiveColor,
    this.negativeColor,
    this.isExpense = false,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final financialColors = theme.extension<FinancialColors>();
    final lang = context.watch<LanguageProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();

    final cf = currencyProvider.formatter;
    final symbol = currencyProvider.currency.symbol;

    final bool actsAsNegative = amount < 0 || isExpense;
    final bool actsAsPositive = amount > 0 && !isExpense;

    String formattedAmount = compact
        ? cf.formatCompact(amount.abs(), lang.localeCode)
        : cf.formatDisplay(amount.abs(), lang.localeCode);

    if (showSign) {
      if (actsAsPositive) formattedAmount = '+$formattedAmount';
      if (actsAsNegative) formattedAmount = '-$formattedAmount';
    }

    Color? textColor;
    if (actsAsPositive) {
      textColor = positiveColor ?? financialColors?.income ?? Colors.green;
    } else if (actsAsNegative) {
      textColor = negativeColor ?? financialColors?.expense ?? Colors.red;
    }

    final baseStyle =
        style?.copyWith(color: textColor) ?? TextStyle(color: textColor);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "$symbol ",
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: formattedAmount,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
