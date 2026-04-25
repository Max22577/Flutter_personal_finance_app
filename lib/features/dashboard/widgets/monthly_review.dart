import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
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
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeFont = textScaler.scale(1) > 1.3;

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 6),
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
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                // Animated Header Section
                _buildAnimatedHeader(context, textScaler),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildAnimatedStats(context, isLargeFont, textScaler),
                      
                      if (monthlyData.income > 0) ...[
                        const SizedBox(height: 16),
                        _buildAnimatedSavingsSection(context, isLargeFont),
                      ],

                      if (showComparison && previousMonthData != null) ...[
                        const SizedBox(height: 16),
                        _buildComparisonTile(context, previousMonthData!, isLargeFont, textScaler),
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

  Widget _buildAnimatedHeader(BuildContext context, TextScaler textScaler) {
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
              Icon(Icons.calendar_today_rounded, size: textScaler.scale(16), color: colors.primary),
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
            Icon(Icons.arrow_forward_ios_rounded, size: textScaler.scale(14), color: colors.primary),
        ],
      ),
    );
  }

  Widget _buildAnimatedStats(BuildContext context, bool isLargeFont, TextScaler textScaler) {
    final theme = Theme.of(context);
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.read<LanguageProvider>();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildAnimatedStatItem(
          label: lang.translate('income'),
          value: monthlyData.income,
          color: financialColors.income,
          icon: Icons.add_circle_outline_rounded, 
          context: context, 
          isExpense: false,
          isFullWidth: isLargeFont, 
          textScaler: textScaler,
        ),
        _buildAnimatedStatItem(
          label: lang.translate('expense'),
          value: monthlyData.expenses,
          color: financialColors.expense,
          icon: Icons.remove_circle_outline_rounded, 
          context: context, 
          isExpense: true,
          isFullWidth: isLargeFont, 
          textScaler: textScaler,
        ),
        _buildAnimatedStatItem(
          label: lang.translate('net_balance'),
          value: monthlyData.net,
          color: monthlyData.net >= 0 ? financialColors.income : financialColors.expense,
          icon: Icons.account_balance_wallet_outlined,
          isFullWidth: true, 
          context: context, 
          isExpense: false, 
          textScaler: textScaler,
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
    required bool isFullWidth,
    required BuildContext context,
    required TextScaler textScaler,
  }) {
    final colors = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      widthFactor: isFullWidth ? 1.0 : 0.48, // Two columns or one based on font size
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: textScaler.scale(18), color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildAnimatedSavingsSection(BuildContext context, bool isLargeFont) {
    final colors = Theme.of(context).colorScheme;
    final savingsRatio = (monthlyData.income - monthlyData.expenses) / monthlyData.income;
    final clampedRatio = savingsRatio.clamp(0.0, 1.0);
    final lang = context.read<LanguageProvider>();


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
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
        // LayoutBuilder gives us the exact pixel width of this specific spot on the screen
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
  Widget _buildComparisonTile(BuildContext context, MonthlyData previousMonthData, bool isLargeFont, TextScaler textScaler) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>() ?? FinancialColors(income: Colors.green, expense: Colors.red);
    final lang = context.read<LanguageProvider>();

    final percentChange = monthlyData.percentageChangeFrom(previousMonthData);
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
          _buildAnimatedTrendIcon(trendColor, isPositive, textScaler),
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
                  style: theme.textTheme.bodySmall?.copyWith(
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

  // Helper to keep the main code clean
  Widget _buildAnimatedTrendIcon(Color trendColor, bool isPositive, TextScaler textScaler) {
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
              size: textScaler.scale(20),
            ),
          ),
        );
      },
    );
  }
}