import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:provider/provider.dart';
import '../../../../models/category.dart';
import '../../../../core/shared_widgets/currency_display.dart';

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

  bool get _isBudgetSet => currentBudget > 0;

  double get _spendingPercentage =>
      _isBudgetSet ? (currentSpending / currentBudget) * 100 : 0;

  Color _getProgressColor(ColorScheme colors) {
    if (!_isBudgetSet) return colors.onSurface.withValues(alpha: 0.3);
    final percentage = _spendingPercentage;
    if (percentage <= 60) return colors.primary;
    if (percentage <= 85) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final iconColor = CategoryIconHelper.getColor(category, colors);
    final remaining = _isBudgetSet ? (currentBudget - currentSpending) : 0.0;
    final progressColor = _getProgressColor(colors);

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onEditPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header 
              _CategoryHeader(
                categoryName: lang.translate(category.name),
                icon: CategoryIconHelper.getIcon(category),
                iconColor: iconColor,
                onEditPressed: onEditPressed,
              ),
              const SizedBox(height: 16),

              // Budget vs Spending Statistics 
              AmountWrapStats(
                colors: colors,
                budgetAmount: currentBudget,
                spendingAmount: currentSpending,
                remainingAmount: remaining,
                isBudgetSet: _isBudgetSet,
                budgetLabel: lang.translate('budget'),
                spentLabel: lang.translate('spent'),
                remainingLabel: lang.translate('remaining'),
              ),
              const SizedBox(height: 12),

              // Progress Section 
              if (_isBudgetSet)
                _BudgetProgressIndicator(
                  percentage: _spendingPercentage,
                  currentSpending: currentSpending,
                  progressColor: progressColor,
                  colors: colors,
                )
              else
                _NoBudgetPlaceholder(
                  colors: colors,
                  message: lang.translate('no_budget_set'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String categoryName;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onEditPressed;

  const _CategoryHeader({
    required this.categoryName,
    required this.icon,
    required this.iconColor,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: textScaler.scale(20).clamp(20, 32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            categoryName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onEditPressed,
          icon: const Icon(Icons.edit, size: 20),
          color: theme.colorScheme.primary,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _BudgetProgressIndicator extends StatelessWidget {
  final double percentage;
  final double currentSpending;
  final Color progressColor;
  final ColorScheme colors;

  const _BudgetProgressIndicator({
    required this.percentage,
    required this.currentSpending,
    required this.progressColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            CurrencyDisplay(
              baseAmount: currentSpending,
              compact: true,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: colors.surfaceContainerHigh,
            color: progressColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _NoBudgetPlaceholder extends StatelessWidget {
  final ColorScheme colors;
  final String message;

  const _NoBudgetPlaceholder({
    required this.colors,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_graph_rounded,
            color: colors.primary.withValues(alpha: 0.6),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// REUSABLE WIDGETS
class AmountWrapStats extends StatelessWidget {
  final ColorScheme colors;
  final double budgetAmount;
  final double spendingAmount;
  final double remainingAmount;
  final bool isBudgetSet;
  final String budgetLabel;
  final String spentLabel;
  final String remainingLabel;

  const AmountWrapStats({
    super.key,
    required this.colors,
    required this.budgetAmount,
    required this.spendingAmount,
    required this.remainingAmount,
    required this.isBudgetSet,
    required this.budgetLabel,
    required this.spentLabel,
    required this.remainingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FinancialFluidTile(
          title: budgetLabel,
          amount: budgetAmount,
          colors: colors,
          isPrimary: true,
        ),
        FinancialFluidTile(
          title: spentLabel,
          amount: spendingAmount,
          colors: colors,
          isExpense: true,
        ),
        FinancialFluidTile(
          title: remainingLabel,
          amount: remainingAmount,
          colors: colors,
          isPositive: isBudgetSet ? remainingAmount >= 0 : null,
        ),
      ],
    );
  }
}

class FinancialFluidTile extends StatelessWidget {
  final String title;
  final double amount;
  final ColorScheme colors;
  final bool isExpense;
  final bool isPrimary;
  final bool? isPositive;

  const FinancialFluidTile({
    super.key,
    required this.title,
    required this.amount,
    required this.colors,
    this.isExpense = false,
    this.isPrimary = false,
    this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color getAmountColor() {
      if (isPositive != null) {
        return isPositive! ? Colors.green : Colors.red;
      }
      return colors.onSurface;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          CurrencyDisplay(
            baseAmount: amount,
            isExpense: isExpense,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isPrimary ? FontWeight.w900 : FontWeight.w600,
              color: getAmountColor(),
            ),
          ),
        ],
      ),
    );
  }
}