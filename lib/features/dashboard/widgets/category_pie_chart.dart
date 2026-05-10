import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/core/widgets/animated_empty_state.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
import 'package:personal_fin/core/widgets/empty_state.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:provider/provider.dart';
import '../view_models/spending_chart_view_model.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key});

  static const List<Color> _vibrantColors = [
    Color(0xFFFF007F), // Vivid Pink
    Color(0xFF00F5D4), // Bright Teal
    Color(0xFF7B2CBF), // Electric Purple
    Color(0xFFFF9F1C), // Bright Orange
    Color(0xFF06D6A0), // Emerald Green
    Color(0xFF5bc0be), // Soft Cyan
    Color(0xFFff0054), // Magenta
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpendingChartViewModel>(
      create: (_) => SpendingChartViewModel(
        context.read<MonthlyTransactionRepository>(),
        context.read<CategoryRepository>(),
      ),
      child: const _CategoryPieChartConsumer(colorsList: _vibrantColors),
    );
  }
}

class _CategoryPieChartConsumer extends StatelessWidget {
  final List<Color> colorsList;

  const _CategoryPieChartConsumer({required this.colorsList});

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final vm = context.watch<SpendingChartViewModel>();

    if (vm.isLoading) {
      return const Center(child: LoadingState());
    }

    if (vm.errorMessage != null) {
      return _ChartCardWrapper(
        child: EmptyState(
          icon: Icons.error_outline,
          title: lang.translate('error_loading'),
          message: vm.errorMessage!,
          actionText: lang.translate('retry'),
          onAction: () => vm.retry(),
        ),
      );
    }

    final data = vm.categoryData;

    if (data.isEmpty) {
      return const _ChartCardWrapper(
        child: Center(
          child: _EmptyChartState(),
        ),
      );
    }

    return _ChartCardWrapper(
      child: _ActiveChartContent(
        categoryData: data,
        colorsList: colorsList,
      ),
    );
  }
}

class _ActiveChartContent extends StatelessWidget {
  final Map<String, double> categoryData;
  final List<Color> colorsList;

  const _ActiveChartContent({
    required this.categoryData,
    required this.colorsList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeFont = textScaler.scale(1) > 1.3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Monthly Spending Breakdown",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Flex(
          direction: isLargeFont ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: isLargeFont ? 200 : 160,
              width: isLargeFont ? double.infinity : 160,
              child: _PieChartGraphic(
                categoryData: categoryData,
                colorsList: colorsList,
              ),
            ),
            if (!isLargeFont) const SizedBox(width: 24),
            if (isLargeFont) const SizedBox(height: 24),
            Expanded(
              flex: isLargeFont ? 0 : 1,
              child: _ChartLegend(
                categoryData: categoryData,
                colorsList: colorsList,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// SUB-COMPONENTS (CHART & LEGEND)
class _PieChartGraphic extends StatelessWidget {
  final Map<String, double> categoryData;
  final List<Color> colorsList;

  const _PieChartGraphic({
    required this.categoryData,
    required this.colorsList,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: textScaler.scale(35),
        sections: _generateSections(colors, textScaler),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(ColorScheme colors, TextScaler textScaler) {
    final totalExpenses = categoryData.values.fold(0.0, (sum, item) => sum + item);
    int index = 0;

    return categoryData.entries.map((entry) {
      final color = colorsList[index % colorsList.length];
      index++;

      final percentage = totalExpenses > 0 ? entry.value / totalExpenses : 0.0;
      final bool shouldShowBadge = percentage >= 0.08;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        radius: textScaler.scale(45),
        showTitle: false,
        badgeWidget: shouldShowBadge
            ? CurrencyDisplay(
                baseAmount: entry.value,
                compact: true,
                isExpense: true,
                positiveColor: colors.onSurface,
                negativeColor: colors.onSurface,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              )
            : null,
        badgePositionPercentageOffset: 0.55,
      );
    }).toList();
  }
}

class _ChartLegend extends StatelessWidget {
  final Map<String, double> categoryData;
  final List<Color> colorsList;

  const _ChartLegend({
    required this.categoryData,
    required this.colorsList,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    int index = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categoryData.entries.map((entry) {
        final color = colorsList[index % colorsList.length];
        index++;

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
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = context.read<LanguageProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedEmptyState(
          message: lang.translate('No data recorded').toUpperCase(),
          imagePath: 'assets/images/empty_wallet_light.svg',
          darkImagePath: 'assets/images/empty_wallet_dark1.svg',
        ),
        const SizedBox(height: 16),
        Text(
          "No transactions found for this month.",
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}


class _ChartCardWrapper extends StatelessWidget {
  final Widget child;

  const _ChartCardWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}