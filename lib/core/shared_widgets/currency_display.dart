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

    final double displayAmount = amount;
    final cf = currencyProvider.formatter;

    final bool actsAsNegative = displayAmount < 0 || isExpense;
    final bool actsAsPositive = displayAmount > 0 && !isExpense;

    // Format using our updated, locale-safe formatter structure
    String formattedAmount = compact
        ? cf.formatCompact(displayAmount.abs(), lang.localeCode)
        : cf.formatDisplay(displayAmount.abs(), lang.localeCode);

    // Append dynamic presentation mathematical symbols if requested
    if (showSign) {
      if (actsAsPositive) formattedAmount = '+ $formattedAmount';
      if (actsAsNegative) formattedAmount = '- $formattedAmount';
    }

    Color? dynamicColor;
    if (actsAsPositive) {
      dynamicColor = positiveColor ?? financialColors?.income ?? Colors.green;
    } else if (actsAsNegative) {
      dynamicColor = negativeColor ?? financialColors?.expense ?? Colors.red;
    }

    // Last resort: If you want the financial color to ALWAYS win
    final TextStyle baseStyle = style?.copyWith(color: dynamicColor) ?? TextStyle(color: dynamicColor);

    return Text(
      formattedAmount,
      style: baseStyle.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

//TextSpan(
  //text: "$symbol ",
  //style: baseStyle.copyWith(
    //fontWeight: FontWeight.w500,
  //),
//),