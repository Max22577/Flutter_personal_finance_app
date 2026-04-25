import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
import 'package:personal_fin/core/widgets/custom_appbar.dart';
import 'package:personal_fin/features/dashboard/view_models/monthly_review_view_model.dart';
import 'package:personal_fin/features/dashboard/widgets/monthly_review.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';

class MonthlyReviewPage extends StatelessWidget {
  final DateTime? month;
  final String? customTitle;

  const MonthlyReviewPage({this.month, this.customTitle, super.key});

  @override
  Widget build(BuildContext context) {
    final targetMonth = month ?? DateTime.now();
    final textScaler = MediaQuery.textScalerOf(context);

    return ChangeNotifierProvider(
      create: (context) => MonthlyReviewViewModel(
        context.read<MonthlyDataRepository>(), 
      )..loadData(targetMonth),
      child: Consumer<MonthlyReviewViewModel>(
        builder: (context, vm, _) {
          final lang = context.watch<LanguageProvider>();
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final text = theme.textTheme;

          return Scaffold(
            backgroundColor: colors.surfaceContainerLow,
            appBar: CustomAppBar(
              title: 'monthly_review_title',
              isRootNav: false,
            ),
            body: _buildBody(context, vm, lang, targetMonth, colors, text, textScaler),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MonthlyReviewViewModel vm, LanguageProvider lang, DateTime month, ColorScheme colors, TextTheme text, TextScaler textScaler) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return _errorState(lang, colors, text, textScaler, message: vm.errorMessage!, onRetry: () => vm.loadData(month));
    }

    if (vm.currentMonthData == null) { 
      return const Center(child: Text("No data found for this month"));
    }

    const baseDuration = Duration(milliseconds: 600);
    const baseCurve = Curves.easeOutQuint;

    return RefreshIndicator(
      onRefresh: () => vm.loadData(month),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeInUp(
              duration: baseDuration,
              curve: baseCurve,
              child: MonthlyReview(
                monthlyData: vm.currentMonthData!,
                previousMonthData: vm.previousMonthData,
                onTap: () => _showMonthlyDetails(context, vm.currentMonthData!),
              ),
            ),
            const SizedBox(height: 24),
            _buildAdditionalInsights(context, vm, lang, colors, text, baseDuration, baseCurve, textScaler),
          ],
        ),
      ),
    );
  }

  Widget _errorState(LanguageProvider lang, ColorScheme colors, TextTheme text, TextScaler textScaler, {required String message, required Function onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: textScaler.scale(64), color: colors.error),
            const SizedBox(height: 16),
            Text(
              lang.translate('err_load_monthly'),
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: .6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => onRetry,
              child: Text(lang.translate('try_again')),
            ),
          ],
        ),
      ),
    );
  }

  // UI helper for insights using ViewModel values
  Widget _buildAdditionalInsights(BuildContext context, MonthlyReviewViewModel vm, LanguageProvider lang, ColorScheme colors, TextTheme text, Duration baseDuration, Curve baseCurve, TextScaler textScaler) {
    const cascadeDelay = Duration(milliseconds: 150);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.translate('visual_breakdown'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FadeInUp(
              duration: baseDuration,
              curve: baseCurve,
              delay: cascadeDelay * 2, // CONCEPTUAL DELAY: 450ms
              child: _buildSavingsGauge(vm, context,  colors, text, textScaler, lang),
            ),
            FadeInUp(
              duration: baseDuration,
              curve: baseCurve,
              delay: cascadeDelay * 2, // CONCEPTUAL DELAY: 600ms
              child: _buildTransactionCount(vm, colors, text, textScaler, lang),
            ),
          ],
        ),
        // Pie Chart Card
        FadeInUp(
          duration: baseDuration,
          curve: baseCurve,
          delay: cascadeDelay * 3, // CONCEPTUAL DELAY: 450ms
          child: _buildPieChartCard(vm, colors, text, lang, textScaler),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          duration: baseDuration,
          curve: baseCurve,
          delay: cascadeDelay * 4, // CONCEPTUAL DELAY: 600ms
          child: _topSpendingCard(vm, vm.currentMonthData!.expenses, colors, text, lang, textScaler),
        ),
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _buildSavingsGauge(MonthlyReviewViewModel vm, BuildContext context, ColorScheme colors, TextTheme text, TextScaler textScaler, LanguageProvider lang) {
  
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(textScaler.scale(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(       
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: EdgeInsets.all(textScaler.scale(12)),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.savings_rounded, // Relevant icon for savings
              color: colors.primary,
              size: textScaler.scale(26),
            ),
          ),
          
          const SizedBox(width: 20),
          // Left Side: Label and Percentage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.translate('saved_label'),
                  style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(vm.savingsRate * 100).toInt()}%',
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),
          
          // Right Side: The Gauge
          SizedBox(
            width: textScaler.scale(70),
            height: textScaler.scale(70),
            child: CircularProgressIndicator(
              value: vm.savingsRate,
              strokeWidth: textScaler.scale(8),
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),     
    );
  }

  Widget _buildTransactionCount(MonthlyReviewViewModel vm, ColorScheme colors, TextTheme text, TextScaler textScaler, LanguageProvider lang) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((textScaler.scale(20))),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Icon Circle
          Container(
            padding: EdgeInsets.all(textScaler.scale(12)),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: colors.primary,
              size: textScaler.scale(26),
            ),
          ),
          const SizedBox(width: 20),
          
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.translate('total_activity'), 
                  style: text.labelLarge?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vm.currentMonthData!.transactionCount}',
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          // Optional: A small "trailing" indicator or arrow to fill the right side
          Icon(Icons.chevron_right, color: colors.primary.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(MonthlyReviewViewModel vm, ColorScheme colors, TextTheme text, LanguageProvider lang, TextScaler textScaler) {
    final categories = vm.topSpendingCategories;

    if (categories.isEmpty) return const SizedBox.shrink();

    const List<Color> chartColors = [
      Color(0xFFFF007F), // Vivid Pink
      Color(0xFF00F5D4), // Bright Teal
      Color(0xFF7B2CBF), // Electric Purple
      Color(0xFFFF9F1C), // Bright Orange
      Color(0xFF06D6A0), // Emerald Green
    ];

    return Container(
      padding: EdgeInsets.all(textScaler.scale(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.translate('spending_distribution').toUpperCase(), 
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w800, 
              letterSpacing: 1.2, 
              color: colors.onSurfaceVariant
            ),
          ),
          const SizedBox(height: 24),
          
          // The Actual Chart
          AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: textScaler.scale(40),
                sections: Iterable.generate(categories.length, (index) {
                  final entry = categories[index];
                  final color = chartColors[index % chartColors.length];
                  final totalExpenses = vm.currentMonthData!.expenses;
                  final percentage = totalExpenses > 0 ? entry.value / totalExpenses : 0.0;

                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    // Display percentage on the slice if it's big enough
                    title: percentage > 0.08 ? '${(percentage * 100).toStringAsFixed(0)}%' : '',
                    radius: textScaler.scale(50),
                    titleStyle: TextStyle(
                      fontSize: textScaler.scale(12),
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mini Legend underneath the chart
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: Iterable.generate(categories.length, (index) {
              final entry = categories[index];
              final color = chartColors[index % chartColors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: textScaler.scale(10),
                    height: textScaler.scale(10),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      lang.translate(entry.key),
                      style: text.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _topSpendingCard(MonthlyReviewViewModel vm,  double expenses, ColorScheme colors, TextTheme text, LanguageProvider lang, TextScaler textScaler) {
    final categories = vm.topSpendingCategories;

    const List<Color> barColors = [
      Color(0xFFFF007F), // Vivid Pink
      Color(0xFF00F5D4), // Bright Teal
      Color(0xFF7B2CBF), // Electric Purple
      Color(0xFFFF9F1C), // Bright Orange
      Color(0xFF06D6A0), // Emerald Green
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((textScaler.scale(20))),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.translate('top_spending').toUpperCase(), style: text.labelMedium?.copyWith(
            fontWeight: FontWeight.bold, letterSpacing: 1.1, color: colors.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Text(lang.translate('no_spending_data'))
          else
            ...Iterable.generate(categories.length, (index) {
              final entry = categories[index];
              final color = barColors[index % barColors.length]; // cycle colors

              return _buildSpendingBar(
                entry.key, 
                entry.value, 
                expenses, 
                color, 
                colors,
                text,
                lang,
                textScaler,
              );
            }),
        ],
      ),
    );
  }
  Widget _buildSpendingBar(String category, double amount, double total, Color color, ColorScheme colors, TextTheme text, LanguageProvider lang, TextScaler textScaler) {
    final percentage = total > 0 ? amount / total : 0.0;
      
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                children: [
                  Text(lang.translate(category), style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text(
                    '(${(percentage * 100).toStringAsFixed(0)}%)', 
                    style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              // Money display
              CurrencyDisplay(
                amount: amount, 
                isExpense: true, 
                compact: true, // keeps it tidy
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: colors.onSurface)
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: colors.surfaceContainerHigh.withValues(alpha: 0.4),
            color: color,
            borderRadius: BorderRadius.circular(10),
            minHeight: textScaler.scale(8),
          ),
        ],
      ),
    );
  }

  void _showMonthlyDetails(BuildContext context, MonthlyData data) {
    final theme = Theme.of(context);
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.read<LanguageProvider>();
    final monthName = DateFormat('MMMM', lang.localeCode).format(data.month);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10)
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$monthName ${lang.translate('summary_title')}', 
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            _buildDetailRow(lang.translate('income_label'), data.income, financialColors.income,),
            _buildDetailRow(lang.translate('expenses_label'), data.expenses, financialColors.expense, isExpense: true),
            const Divider(height: 24),
            _buildDetailRow(lang.translate('net_profit'), data.net, theme.colorScheme.primary),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double value, Color color, {bool isExpense = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          CurrencyDisplay(amount: value, isExpense: isExpense, compact: false, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}