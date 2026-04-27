import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/currency_display.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compactAmount;
  final bool alwaysShowSign;

  const TransactionTile({
    required this.transaction,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.compactAmount = false,
    this.alwaysShowSign = true, // Default true for tiles
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>() ?? FinancialColors(income: Colors.green, expense: Colors.red);
    final lang = context.watch<LanguageProvider>();
    final textScaler = MediaQuery.textScalerOf(context);

    final isIncome = transaction.type == 'Income';
    final iconColor = isIncome
        ? financialColors.income
        : financialColors.expense;
    final bgColor = isIncome
        ? financialColors.income.withValues(alpha: 0.1)
        : financialColors.expense.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Optional: Add tap action
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row: Title and Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: textScaler.scale(36), // Scales with font size
                      height: textScaler.scale(36),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: iconColor,
                        size: textScaler.scale(18),
                      ),
                    ),

                    // Title - Takes full width
                    Expanded(
                      child: Wrap( // Wrap handles cases where Title + Amount are too wide
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Title
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: textScaler.scale(200)),
                            child: Text(
                              transaction.title,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          // Amount
                          CurrencyDisplay(
                            amount: transaction.amount,
                            isExpense: !isIncome,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isIncome ? financialColors.income : financialColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category and Time inline
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (categoryName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lang.translate(categoryName),
                          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    Text(
                      DateFormat('h:mm a').format(transaction.date),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Amount and date column
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    _buildActionButton(
                      context: context,
                      icon: Icons.edit_outlined,
                      label: lang.translate('edit'),
                      color: colors.primary,
                      onPressed: onEdit,
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.delete_outline,
                      label: lang.translate('delete'),
                      color: colors.error,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: textScaler.scale(16), color: color),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size(0, textScaler.scale(32)),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
