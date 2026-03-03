import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../shared/currency_display.dart';

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
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.watch<LanguageProvider>();

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
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(8),
          onTap: () {}, // Optional: Add tap action
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row: Title and Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
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
                        size: 16,
                      ),
                    ),

                    // Title - Takes full width
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                          // Category and Time inline
                          Row(
                            children: [
                              // Category Chip
                              if (categoryName.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    lang.translate(categoryName),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],

                              // Time
                              Text(
                                DateFormat('h:mm a').format(transaction.date),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Amount and date column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Amount using CurrencyDisplay widget
                        CurrencyDisplay(
                          amount: transaction.amount,
                          isExpense: isIncome ? false : true,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          compact: compactAmount,
                          showSign: alwaysShowSign,
                          positiveColor: financialColors.income,
                          negativeColor: financialColors.expense,
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      context: context,
                      icon: Icons.edit_outlined,
                      label: lang.translate('edit'),
                      color: colors.primary,
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 8),
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

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
