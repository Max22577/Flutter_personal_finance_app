import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
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
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.watch<LanguageProvider>();

    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeFont = textScaler.scale(1) > 1.3;

    return Container(
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
          // Decorative background element for a "polished" look
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: textScaler.scale(60),
              backgroundColor: (net >= 0 ? financialColors.income : financialColors.expense).withValues(alpha: 0.05),
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
                  _buildHeader(textTheme, colors, textScaler),
                  const SizedBox(height: 20),
                  _buildMainBalance(textTheme, colors, lang),
                  const SizedBox(height: 16),
                  _buildAnimatedStats(context, lang, isLargeFont, textScaler),
                  if (previousMonthData != null) ...[
                    const SizedBox(height: 12),
                    _buildComparisonTile(context, lang, isLargeFont, textScaler),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colors, TextScaler textScaler) {
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
        Icon(Icons.more_horiz, color: colors.onSurface.withValues(alpha: 0.4), size: textScaler.scale(20)),
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
                color: colors.onSurface,
                letterSpacing: 0.2,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, double amount, Color color, IconData icon, bool isExpense, bool isLargeFont, TextScaler textScaler) {
    return SizedBox(
      width: isLargeFont ? double.infinity : null, // Take full width if font is large
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: textScaler.scale(12), color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: textScaler.scale(10), fontWeight: FontWeight.w600)),
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

  Widget _buildAnimatedStats(BuildContext context, LanguageProvider lang, bool isLargeFont, TextScaler textScaler) {
    final theme = Theme.of(context);
    final financialColors = theme.extension<FinancialColors>()!;
    

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildStatItem(lang.translate('income'), income, financialColors.income, Icons.arrow_upward, false, isLargeFont, textScaler),
        const SizedBox(width: 16),
        _buildStatItem(lang.translate('expense'), expenses, financialColors.expense, Icons.arrow_downward, true, isLargeFont, textScaler),
      ],
    );
  }

  Widget _buildComparisonTile(BuildContext context, LanguageProvider lang, bool isLargeFont, TextScaler textScaler) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final previousNet = (previousMonthData?.income ?? 0) - (previousMonthData?.expenses ?? 0);
    final netDifference = net - previousNet;
    final isImproved = netDifference >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isImproved ? financialColors.income.withValues(alpha: 0.1) : financialColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap( // Wrap ensures the currency doesn't clip if the text is long
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