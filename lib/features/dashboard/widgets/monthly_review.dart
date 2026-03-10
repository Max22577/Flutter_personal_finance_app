import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';
 

class MonthlyReview extends StatelessWidget {
  final MonthlyData monthlyData;
  final MonthlyData? previousMonthData;
  final VoidCallback? onTap;
  final bool showDetailsButton;
  final bool showComparison;

  const MonthlyReview({
    super.key,
    required this.monthlyData,
    this.previousMonthData,
    this.onTap,
    this.showDetailsButton = true,
    this.showComparison = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                // Animated Header Section
                _buildAnimatedHeader(context),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildAnimatedStats(context),
                      
                      if (monthlyData.income > 0) ...[
                        const SizedBox(height: 24),
                        _buildAnimatedSavingsSection(context),
                      ],

                      if (showComparison && previousMonthData != null) ...[
                        const SizedBox(height: 20),
                        _buildComparisonTile(context),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                monthlyData.formattedMonth.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          if (showDetailsButton)
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.primary),
        ],
      ),
    );
  }

  Widget _buildAnimatedStats(BuildContext context) {
    final theme = Theme.of(context);
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.read<LanguageProvider>();

    return Column(
      children: [
        // Top Row: Income and Expenses
        Row(
          children: [
            _buildAnimatedStatItem(
              label: lang.translate('income'),
              value: monthlyData.income,
              color: financialColors.income,
              icon: Icons.add_circle_outline_rounded, context: context, isExpense: false
            ),
            const SizedBox(width: 12),
            _buildAnimatedStatItem(
              label: lang.translate('expense'),
              value: monthlyData.expenses,
              color: financialColors.expense,
              icon: Icons.remove_circle_outline_rounded, context: context, isExpense: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom Row: Net (Full Width)
        _buildAnimatedStatItem(
          label: lang.translate('net_balance'),
          value: monthlyData.net,
          color: monthlyData.net >= 0 ? financialColors.income : financialColors.expense,
          icon: Icons.account_balance_wallet_outlined,
          isFullWidth: true, context: context, isExpense: false,
        ),
      ],
    );
  }

  Widget _buildAnimatedStatItem({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required bool isExpense,
    bool isFullWidth = false,
    required context,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      flex: isFullWidth ? 0 : 1, 
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutBack,
                    builder: (context, animatedValue, child) {
                      return CurrencyDisplay(
                        amount: animatedValue,
                        style: TextStyle(
                          fontSize: isFullWidth ? 15 : 13,
                          fontWeight: FontWeight.w900,
                          color: colors.onSurface,
                          letterSpacing: -1,
                        ),
                        showSign: false,
                        isExpense: isExpense,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSavingsSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final savingsRatio = (monthlyData.income - monthlyData.expenses) / monthlyData.income;
    final clampedRatio = savingsRatio.clamp(0.0, 1.0);
    final lang = context.read<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(lang.translate('savings_efficiency'), style: TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              '${(clampedRatio * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clampedRatio),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.fastOutSlowIn,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildComparisonTile(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final cf = context.watch<CurrencyProvider>().formatter;
    final lang = context.read<LanguageProvider>();

    final percentChange = monthlyData.percentageChangeFrom(previousMonthData!);
    final isPositive = percentChange >= 0;
    final trendColor = isPositive ? financialColors.income : financialColors.expense;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Icon stays fixed on the left
          _buildAnimatedTrendIcon(trendColor, isPositive),
          const SizedBox(width: 14),

          // 2. Text Content now handles the overflow by stacking
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? lang.translate('perf_up') : lang.translate('perf_down'),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                // Main comparison text
                Text(
                  '${percentChange.abs().toStringAsFixed(1)}% ${isPositive ? lang.translate('better') : lang.translate('lower')} ${lang.translate('than_last_month')}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                // 3. Sub-row for the "Previous" data to keep things compact
                Row(
                  children: [
                    Text(
                      '${lang.translate('previous')}: ',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      cf.format(previousMonthData!.net, lang.localeCode),
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),                      
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to keep the main code clean
  Widget _buildAnimatedTrendIcon(Color trendColor, bool isPositive) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${monthlyData.formattedMonth}_$isPositive'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: trendColor,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}