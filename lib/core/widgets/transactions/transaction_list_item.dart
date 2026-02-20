import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../shared/currency_display.dart';
import '../theme/app_theme.dart';


class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final String categoryName;
  final bool compactAmount;
  final bool alwaysShowSign;

  const TransactionListItem({
    required this.transaction,
    required this.categoryName,
    this.compactAmount = false,
    this.alwaysShowSign = true, 
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>()!;
    
    final isIncome = transaction.type == 'Income';
    final amount = transaction.amount;
    final amountColor = isIncome ? financialColors.income : financialColors.expense;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: amountColor, size: 20),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CurrencyDisplay(
              amount: amount,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              compact: compactAmount,
              showSign: alwaysShowSign,
              positiveColor: financialColors.income,
              negativeColor: financialColors.expense,
            ),
            const SizedBox(height: 4),
            
            // Date
            Text(
              DateFormat('MMM d').format(transaction.date),
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            )
          ],
        ),
      ),
    );
  }
}