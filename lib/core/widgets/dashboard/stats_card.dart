import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart'; 
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
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.watch<LanguageProvider>();

    return Container(
      decoration: BoxDecoration(
        // Gradient background makes the card look more premium than solid surface
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background element for a "polished" look
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: (net >= 0 ? financialColors.income : financialColors.expense).withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(textTheme, colors),
                  const Spacer(),
                  _buildMainBalance(textTheme, colors, lang),
                  const SizedBox(height: 16),
                  _buildAnimatedStats(context, lang),
                  if (previousMonthData != null) ...[
                    const SizedBox(height: 12),
                    _buildComparisonTile(context, lang),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: textTheme.titleMedium?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Icon(Icons.more_horiz, color: colors.onSurface.withValues(alpha: 0.4)),
      ],
    );
  }

  Widget _buildMainBalance(TextTheme textTheme, ColorScheme colors, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('net_balance'),
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: net),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutBack, // Smooth entrance
          builder: (context, value, child) {
            return CurrencyDisplay(
              amount: value,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
                letterSpacing: 0.2,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, double amount, Color color, IconData icon, bool isExpense) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurrencyDisplay(
              isExpense: isExpense,
              amount: amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStats(BuildContext context, LanguageProvider lang) {
    final theme = Theme.of(context);
    final financialColors = theme.extension<FinancialColors>()!;
    

    return Row(
      children: [
        _buildStatItem(lang.translate('income'), income, financialColors.income, Icons.arrow_upward, false),
        const SizedBox(width: 16),
        _buildStatItem(lang.translate('expense'), expenses, financialColors.expense, Icons.arrow_downward, true),
      ],
    );
  }

  Widget _buildComparisonTile(BuildContext context, LanguageProvider lang) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final previousNet = (previousMonthData?.income ?? 0) - (previousMonthData?.expenses ?? 0);
    final netDifference = net - previousNet;
    final isImproved = netDifference >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isImproved ? financialColors.income.withValues(alpha: 0.1) : financialColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImproved ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isImproved ? financialColors.income : financialColors.expense,
          ),
          const SizedBox(width: 6),
          Text(
            '${isImproved ? lang.translate('improved') : lang.translate('declined')} ${lang.translate('by')} ',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          CurrencyDisplay(
            amount: netDifference.abs(),
            style: TextStyle(
              color: isImproved ? financialColors.income : financialColors.expense,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}