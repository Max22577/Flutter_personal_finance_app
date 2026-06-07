import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/features/monthly_review/views/widgets/animated_trend_icon.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';

class MonthlyReviewSummary extends StatelessWidget {
  final MonthlyData monthlyData;
  final MonthlyData? previousMonthData;
  final VoidCallback? onTap;
  final bool isDashboard; // Pass true when called from dashboard

  const MonthlyReviewSummary({
    super.key,
    required this.monthlyData,
    this.previousMonthData,
    this.onTap,
    this.isDashboard = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    // Swap text colors because this widget sits directly on your colored gradient canvas
    final baseTextColor = colors.onPrimary;

    return InkWell(
      onTap: onTap,
      splashColor: baseTextColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Net Balance Hero Segment (Centered & Prominent)
            Text(
              monthlyData.formattedMonth.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: baseTextColor.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: textScaler.scale(4)),
            CurrencyDisplay(
              amount: monthlyData.net,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: baseTextColor,
                letterSpacing: -0.5,
              ),
              showSign: true,
            ),
            SizedBox(height: textScaler.scale(24)),

            // Income vs Expenses Core Segment Row
            Row(
              children: [
                Expanded(
                  child: _MiniSummaryTile(
                    label: 'INCOME',
                    value: monthlyData.income,
                    textColor: baseTextColor,
                    icon: Icons.arrow_upward_rounded,
                    iconColor: Colors.greenAccent,
                    isExpense: false,
                  ),
                ),
                Container(
                  height: textScaler.scale(32),
                  width: 1,
                  color: baseTextColor.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _MiniSummaryTile(
                    label: 'EXPENSES',
                    value: monthlyData.expenses,
                    textColor: baseTextColor,
                    icon: Icons.arrow_downward_rounded,
                    iconColor: Colors.redAccent,
                    isExpense: true,
                  ),
                ),
              ],
            ),
            
            // Conditional Deep Analytics (Hidden on Dashboard for optimal whitespace)
            if (!isDashboard) ...[
              const SizedBox(height: 24),
              if (monthlyData.income > 0)
                _SavingsEfficiencyProgress(
                  income: monthlyData.income,
                  expenses: monthlyData.expenses,
                ),
              if (previousMonthData != null) ...[
                const SizedBox(height: 16),
                _MonthlyComparisonTile(
                  currentMonthData: monthlyData,
                  previousMonthData: previousMonthData!,
                  isLargeFont: textScaler.scale(1) > 1.3,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Minimalistic item widget optimized to sit cleanly inside the row structure
class _MiniSummaryTile extends StatelessWidget {
  final String label;
  final double value;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final bool isExpense;

  const _MiniSummaryTile({
    required this.label,
    required this.value,
    required this.textColor,
    required this.icon,
    required this.iconColor,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.6),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CurrencyDisplay(
          isExpense: isExpense,
          amount: value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          positiveColor: isExpense ? null : iconColor, 
          negativeColor: isExpense ? iconColor : null,
          showSign: false,         
        ),
      ],
    );
  }
}

class _SavingsEfficiencyProgress extends StatelessWidget {
  final double income;
  final double expenses;

  const _SavingsEfficiencyProgress({
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = context.read<LanguageProvider>();
    
    final savingsRatio = (income - expenses) / income;
    final clampedRatio = savingsRatio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                lang.translate('savings_efficiency'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${(clampedRatio * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clampedRatio),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.fastOutSlowIn,
                  builder: (context, value, child) {
                    return Container(
                      width: constraints.maxWidth * value,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MonthlyComparisonTile extends StatelessWidget {
  final MonthlyData currentMonthData;
  final MonthlyData previousMonthData;
  final bool isLargeFont;

  const _MonthlyComparisonTile({
    required this.currentMonthData,
    required this.previousMonthData,
    required this.isLargeFont,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>() ?? 
        FinancialColors(income: Colors.green, expense: Colors.red);
    final lang = context.read<LanguageProvider>();

    final percentChange = currentMonthData.percentageChangeFrom(previousMonthData);
    final isPositive = percentChange >= 0;
    final trendColor = isPositive ? financialColors.income : financialColors.expense;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Flex(
        direction: isLargeFont ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: isLargeFont ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          AnimatedTrendIcon(
            monthId: currentMonthData.formattedMonth,
            isPositive: isPositive,
            trendColor: trendColor,
          ),
          SizedBox(width: isLargeFont ? 0 : 16, height: isLargeFont ? 12 : 0),
          Expanded(
            flex: isLargeFont ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentChange.abs().toStringAsFixed(1)}% ${isPositive ? lang.translate('better') : lang.translate('lower')} ${lang.translate('than_last_month')}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  lang.translate('than_last_month'),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}