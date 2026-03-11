import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:provider/provider.dart';
import '../../../models/category.dart';
import '../../../core/widgets/shared/currency_display.dart';

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
    final lang = context.watch<LanguageProvider>();
    final icon = CategoryIconHelper.getIcon(category.name);
    final iconColor = CategoryIconHelper.getColor(category.name, colors);

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                    backgroundColor: iconColor.withValues(alpha: 0.15),
                    radius: 20,
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.translate(category.name),
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
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountTile(
                          title: lang.translate('budget'),
                          amount: currentBudget,
                          theme: theme,
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAmountTile(
                          title: lang.translate('spent'),
                          amount: currentSpending,
                          theme: theme,
                          isExpense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildAmountTile(
                        title: lang.translate('remaining'),
                        amount: remaining,
                        theme: theme,
                        isPositive: isBudgetSet ? remaining >= 0 : null,
                      ),
                    ],
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
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _spendingPercentage),
                          duration: const Duration(milliseconds: 700),
                          builder: (context, value, child) {
                            return Text(
                              '${value.toStringAsFixed(0)}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _progressColor,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
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
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _spendingPercentage / 100),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: colors.surfaceContainerHigh,
                            color: _progressColor,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    )
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
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
                        lang.translate('no_budget_set'),
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

  Widget _buildAmountTile({
    required String title,
    required double amount,
    required ThemeData theme,
    bool isExpense = false,
    bool isPrimary = false,
    bool? isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          CurrencyDisplay(
            amount: amount,
            isExpense: isExpense,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isPrimary ? FontWeight.w500 : FontWeight.w400,
              color: isPositive != null
                  ? (isPositive ? Colors.green : Colors.red)
                  : colors.onSurface,
            ),
            compact: false,
          ),
        ],
      ),
    );
  }

}