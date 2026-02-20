import 'package:flutter/material.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/currency_provider.dart';

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
    // Assuming you've kept your ThemeExtension for custom financial colors
    final financialColors = theme.extension<FinancialColors>();

    // 1. Get the synchronous formatter from your Provider
    final cf = context.watch<CurrencyProvider>().formatter;

    // 2. Logic to determine if it's visually negative/positive
    final bool actsAsNegative = amount < 0 || isExpense;
    final bool actsAsPositive = amount > 0 && !isExpense;

    // 3. Format the amount immediately (no FutureBuilder needed!)
    String displayText = compact 
        ? cf.formatCompact(amount.abs()) 
        : cf.formatDisplay(amount.abs());

    // 4. Handle signs manually based on your parameters
    if (showSign) {
      if (actsAsPositive) {
        displayText = '+$displayText';
      } else if (actsAsNegative) {
        displayText = '-$displayText';
      }
    }

    // 5. Determine the appropriate color
    Color? textColor;
    if (actsAsPositive) {
      textColor = positiveColor ?? financialColors?.income ?? Colors.green;
    } else if (actsAsNegative) {
      textColor = negativeColor ?? financialColors?.expense ?? Colors.red;
    }

    return Text(
      displayText,
      style: style?.copyWith(color: textColor) ?? TextStyle(color: textColor),
    );
  }
}

// Usage example:
// CurrencyDisplay(
//   amount: 1500.75,
//   style: Theme.of(context).textTheme.titleLarge,
//   showSign: true,
// )