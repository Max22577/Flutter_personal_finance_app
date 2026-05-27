import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/core/shared_widgets/custom_appbar.dart';
import 'package:personal_fin/features/dashboard/view_models/monthly_review_view_model.dart';
import 'package:personal_fin/features/dashboard/views/widgets/monthly_review.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';


class MonthlyReviewPage extends StatelessWidget {
  final DateTime? month;
  final String? customTitle;

  const MonthlyReviewPage({this.month, this.customTitle, super.key});

  @override
  Widget build(BuildContext context) {
    final targetMonth = month ?? DateTime.now();

    return Provider<MonthlyReviewViewModel>(
      create: (context) => MonthlyReviewViewModel(
        context.read<MonthlyDataRepository>(),
        context.read<CurrencyProvider>(),
      ),
      child: _MonthlyReviewScaffold(targetMonth: targetMonth),
    );
  }
}


class _MonthlyReviewScaffold extends StatelessWidget {
  final DateTime targetMonth;

  const _MonthlyReviewScaffold({required this.targetMonth});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: const CustomAppBar(
        title: 'monthly_review_title',
        isRootNav: false,
      ),
      body: _MonthlyReviewBody(targetMonth: targetMonth),
    );
  }
}

class _MonthlyReviewBody extends StatelessWidget {
  final DateTime targetMonth;

  const _MonthlyReviewBody({required this.targetMonth});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MonthlyReviewViewModel>();

  return StreamBuilder<List<MonthlyData>>(
    stream: vm.getReviewDataStream(targetMonth),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return _ErrorStateView(message: snapshot.error.toString(), onRetry: () { /* ... */ });
      }

      final data = snapshot.data;
      if (data == null || data.isEmpty) return const Center(child: Text("No data"));

      const baseDuration = Duration(milliseconds: 600);
      const baseCurve = Curves.easeOutQuint;

      return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeInUp(
                duration: baseDuration,
                curve: baseCurve,
                child: MonthlyReview(
                  monthlyData: data[0],
                  previousMonthData: data[1],
                  onTap: () => _showMonthlyDetails(context, data[0]),
                ),
              ),
              const SizedBox(height: 24),
              const _AdditionalInsightsSection(),
            ],
          ),
        );
      }
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$monthName ${lang.translate('summary_title')}',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: lang.translate('income_label'),
              value: data.income,
              color: financialColors.income,
            ),
            _DetailRow(
              label: lang.translate('expenses_label'),
              value: data.expenses,
              color: financialColors.expense,
              isExpense: true,
            ),
            const Divider(height: 24),
            _DetailRow(
              label: lang.translate('net_profit'),
              value: data.net,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}


class _AdditionalInsightsSection extends StatelessWidget {
  const _AdditionalInsightsSection();

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final theme = Theme.of(context);

    const baseDuration = Duration(milliseconds: 600);
    const baseCurve = Curves.easeOutQuint;
    const cascadeDelay = Duration(milliseconds: 150);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('visual_breakdown'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FadeInUp(
              duration: baseDuration,
              curve: baseCurve,
              delay: cascadeDelay * 2,
              child: const _SavingsGaugeCard(),
            ),
            FadeInUp(
              duration: baseDuration,
              curve: baseCurve,
              delay: cascadeDelay * 2,
              child: const _TransactionCountCard(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FadeInUp(
          duration: baseDuration,
          curve: baseCurve,
          delay: cascadeDelay * 3,
          child: const _DistributionPieChartCard(),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          duration: baseDuration,
          curve: baseCurve,
          delay: cascadeDelay * 4,
          child: const _TopSpendingCard(),
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}

// CARDS & DISPLAYS

class _SavingsGaugeCard extends StatelessWidget {
  const _SavingsGaugeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.watch<LanguageProvider>();
    final vm = context.watch<MonthlyReviewViewModel>();

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
              Icons.savings_rounded,
              color: colors.primary,
              size: textScaler.scale(26),
            ),
          ),
          const SizedBox(width: 20),
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
}

class _TransactionCountCard extends StatelessWidget {
  const _TransactionCountCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.watch<LanguageProvider>();
    final vm = context.watch<MonthlyReviewViewModel>();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(textScaler.scale(20)),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
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
                  '${vm.currentMonthData?.transactionCount ?? 0}',
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.primary.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _DistributionPieChartCard extends StatelessWidget {
  const _DistributionPieChartCard();

  static const List<Color> chartColors = [
    Color(0xFFFF007F), // Vivid Pink
    Color(0xFF00F5D4), // Bright Teal
    Color(0xFF7B2CBF), // Electric Purple
    Color(0xFFFF9F1C), // Bright Orange
    Color(0xFF06D6A0), // Emerald Green
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.watch<LanguageProvider>();
    final vm = context.watch<MonthlyReviewViewModel>();

    final categories = vm.topSpendingCategories;
    if (categories.isEmpty) return const SizedBox.shrink();

    final totalExpenses = vm.currentMonthData?.expenses ?? 0.0;

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
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: textScaler.scale(40),
                sections: Iterable.generate(categories.length, (index) {
                  final entry = categories[index];
                  final color = chartColors[index % chartColors.length];
                  final percentage = totalExpenses > 0 ? entry.value / totalExpenses : 0.0;

                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
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
}

class _TopSpendingCard extends StatelessWidget {
  const _TopSpendingCard();

  static const List<Color> barColors = [
    Color(0xFFFF007F), // Vivid Pink
    Color(0xFF00F5D4), // Bright Teal
    Color(0xFF7B2CBF), // Electric Purple
    Color(0xFFFF9F1C), // Bright Orange
    Color(0xFF06D6A0), // Emerald Green
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.watch<LanguageProvider>();
    final vm = context.watch<MonthlyReviewViewModel>();

    final categories = vm.topSpendingCategories;
    final totalExpenses = vm.currentMonthData?.expenses ?? 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(textScaler.scale(20)),
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
          Text(
            lang.translate('top_spending').toUpperCase(),
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Text(lang.translate('no_spending_data'))
          else
            ...Iterable.generate(categories.length, (index) {
              final entry = categories[index];
              final color = barColors[index % barColors.length];

              return _SpendingBarItem(
                category: entry.key,
                amount: entry.value,
                total: totalExpenses,
                color: color,
              );
            }),
        ],
      ),
    );
  }
}

class _SpendingBarItem extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final Color color;

  const _SpendingBarItem({
    required this.category,
    required this.amount,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.read<LanguageProvider>();

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
                  Text(
                    lang.translate(category),
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${(percentage * 100).toStringAsFixed(0)}%)',
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              CurrencyDisplay(
                amount: amount,
                isExpense: true,
                compact: true,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
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
}


class _ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorStateView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.read<LanguageProvider>();

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
              onPressed: onRetry,
              child: Text(lang.translate('try_again')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isExpense;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    this.isExpense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          CurrencyDisplay(
            amount: value,
            isExpense: isExpense,
            compact: false,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}