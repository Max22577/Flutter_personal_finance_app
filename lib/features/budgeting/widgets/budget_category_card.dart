import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:provider/provider.dart';
import '../../../models/category.dart';
import '../../../core/widgets/currency_display.dart';

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
    final icon = CategoryIconHelper.getIcon(category);
    final iconColor = CategoryIconHelper.getColor(category, colors);
    final textScaler = MediaQuery.textScalerOf(context);

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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: textScaler.scale(20).clamp(20, 32)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.translate(category.name),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
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
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Budget vs Spending
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFluidAmountTile(
                    context: context,
                    title: lang.translate('budget'),
                    amount: currentBudget,
                    isPrimary: true,
                  ),
                  _buildFluidAmountTile(
                    context: context,
                    title: lang.translate('spent'),
                    amount: currentSpending,
                    isExpense: true,
                  ),
                  _buildFluidAmountTile(
                    context: context,
                    title: lang.translate('remaining'),
                    amount: remaining,
                    isPositive: isBudgetSet ? remaining >= 0 : null,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              if (isBudgetSet) ...[
                _buildProgressSection(theme, textScaler),
              ] else ...[
                _buildNoBudgetPlaceholder(colors, lang, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFluidAmountTile({
    required BuildContext context,
    required String title,
    required double amount,
    bool isExpense = false,
    bool isPrimary = false,
    bool? isPositive,
  }) {
    final theme = Theme.of(context);
    // Ensure the tile occupies at least 100px but expands to fill space in the Wrap
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
            amount: amount,
            isExpense: isExpense,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isPrimary ? FontWeight.w900 : FontWeight.w600,
              color: isPositive != null 
                  ? (isPositive ? Colors.green : Colors.red) 
                  : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, TextScaler textScaler) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_spendingPercentage.toStringAsFixed(0)}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: _progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Progress indicators often look better with "Compact" amounts in fluid bars
            CurrencyDisplay(
              amount: currentSpending,
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
            value: (_spendingPercentage / 100).clamp(0.0, 1.0),
            backgroundColor: colors.surfaceContainerHigh,
            color: _progressColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildNoBudgetPlaceholder(ColorScheme colors, LanguageProvider lang, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph_rounded, color: colors.primary.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 8),
          Text(
            lang.translate('no_budget_set'),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

}