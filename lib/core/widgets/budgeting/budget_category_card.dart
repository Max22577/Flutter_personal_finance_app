import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../shared/currency_display.dart';

class BudgetCategoryCard extends StatelessWidget {
  final Category category;
  final double currentBudget;
  final double currentSpending;
  final VoidCallback onEditPressed;
  final ColorScheme colors;

  const BudgetCategoryCard({
    super.key,
    required this.category,
    required this.currentBudget,
    required this.currentSpending,
    required this.onEditPressed,
    required this.colors,
  });

  double get _spendingPercentage => currentBudget > 0 
      ? (currentSpending / currentBudget) * 100 
      : 0;

  Color get _progressColor {
    if (currentBudget <= 0) return colors.onSurface.withValues(alpha: 0.3);
    final percentage = _spendingPercentage;
    if (percentage <= 60) return colors.primary;
    if (percentage <= 85) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBudgetSet = currentBudget > 0;
    final remaining = isBudgetSet ? (currentBudget - currentSpending) : 0.0;

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onEditPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and name
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                    radius: 20,
                    child: Icon(
                      Icons.category,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onEditPressed,
                    icon: Icon(
                      Icons.edit,
                      color: colors.primary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Budget vs Spending
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAmountColumn(
                    title: 'Budget',
                    amount: currentBudget,
                    theme: theme,
                    isPrimary: true,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colors.outline.withValues(alpha: 0.3),
                  ),
                  _buildAmountColumn(
                    title: 'Spent',
                    amount: currentSpending,
                    theme: theme,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colors.outline.withValues(alpha: 0.3),
                  ),
                  _buildAmountColumn(
                    title: 'Remaining',
                    amount: remaining,
                    theme: theme,
                    isPositive: isBudgetSet ? remaining >= 0 : null,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              if (isBudgetSet)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_spendingPercentage.toStringAsFixed(1)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _progressColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${currentSpending.toStringAsFixed(2)} / ${currentBudget.toStringAsFixed(2)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _spendingPercentage / 100,
                      backgroundColor: colors.surfaceContainerHighest,
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No budget set',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn({
    required String title,
    required double amount,
    required ThemeData theme,
    bool isPrimary = false,
    bool? isPositive,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          CurrencyDisplay(
            amount: amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
              color: isPositive != null
                  ? (isPositive ? Colors.green : Colors.red)
                  : colors.onSurface,
            ),
            compact: true,
            showSign: false,
          ),
        ],
      ),
    );
  }
}