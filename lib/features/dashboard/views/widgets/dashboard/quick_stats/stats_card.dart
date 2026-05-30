import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/core/theme/app_theme.dart'; 
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';

class StatCard extends StatelessWidget {
  final String title;
  final double income;
  final double expenses;
  final MonthlyData? previousMonthData;

  const StatCard({
    required this.title,
    required this.income,
    required this.expenses,
    this.previousMonthData,
    super.key,
  });

  double get net => income - expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeFont = textScaler.scale(1) > 1.3;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surface,
            colors.surfaceContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: textScaler.scale(60),
              backgroundColor: (net >= 0 ? financialColors.income : financialColors.expense)
                  .withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatCardHeader(title: title),
                  const SizedBox(height: 20),
                  _StatCardMainBalance(netBalance: net),
                  const SizedBox(height: 16),
                  _StatCardBreakdown(
                    income: income,
                    expenses: expenses,
                    isLargeFont: isLargeFont,
                  ),
                  if (previousMonthData != null) ...[
                    const SizedBox(height: 12),
                    _StatCardComparison(
                      currentNet: net,
                      previousMonthData: previousMonthData!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardHeader extends StatelessWidget {
  final String title;

  const _StatCardHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Icon(
          Icons.more_horiz,
          color: colors.onSurface.withValues(alpha: 0.4),
          size: textScaler.scale(20),
        ),
      ],
    );
  }
}

class _StatCardMainBalance extends StatelessWidget {
  final double netBalance;

  const _StatCardMainBalance({required this.netBalance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('net_balance'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: netBalance),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return CurrencyDisplay(
              amount: value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
                letterSpacing: 0.2,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatCardBreakdown extends StatelessWidget {
  final double income;
  final double expenses;
  final bool isLargeFont;

  const _StatCardBreakdown({
    required this.income,
    required this.expenses,
    required this.isLargeFont,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.read<LanguageProvider>();

    if (isLargeFont) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatItem(
            label: lang.translate('income'),
            amount: income,
            color: financialColors.income,
            icon: Icons.arrow_upward,
            isExpense: false,
            isLargeFont: true,
          ),
          const SizedBox(height: 12),
          _StatItem(
            label: lang.translate('expense'),
            amount: expenses,
            color: financialColors.expense,
            icon: Icons.arrow_downward,
            isExpense: true,
            isLargeFont: true,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: lang.translate('income'),
            amount: income,
            color: financialColors.income,
            icon: Icons.arrow_upward,
            isExpense: false,
            isLargeFont: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatItem(
            label: lang.translate('expense'),
            amount: expenses,
            color: financialColors.expense,
            icon: Icons.arrow_downward,
            isExpense: true,
            isLargeFont: false,
          ),
        ),
      ],
    );
  }
}

class _StatCardComparison extends StatelessWidget {
  final double currentNet;
  final MonthlyData previousMonthData;

  const _StatCardComparison({
    required this.currentNet,
    required this.previousMonthData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.read<LanguageProvider>();

    final previousNet = previousMonthData.income - previousMonthData.expenses;
    final netDifference = currentNet - previousNet;
    final isImproved = netDifference >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isImproved ? financialColors.income : financialColors.expense)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            isImproved ? Icons.trending_up : Icons.trending_down,
            size: textScaler.scale(14),
            color: isImproved ? financialColors.income : financialColors.expense,
          ),
          const SizedBox(width: 6),
          Text(
            '${isImproved ? lang.translate('improved') : lang.translate('declined')} ${lang.translate('by')} ',
            style: TextStyle(
              fontSize: textScaler.scale(11),
              color: colors.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          CurrencyDisplay(
            amount: netDifference.abs(),
            style: TextStyle(
              fontSize: textScaler.scale(11),
              color: isImproved ? financialColors.income : financialColors.expense,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isExpense;
  final bool isLargeFont;

  const _StatItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isExpense,
    required this.isLargeFont,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return SizedBox(
      width: isLargeFont ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: textScaler.scale(12), color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: textScaler.scale(10),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CurrencyDisplay(
            isExpense: isExpense,
            amount: amount,
            style: TextStyle(
              fontSize: textScaler.scale(16),
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}