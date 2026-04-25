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
    final theme = Theme.of(context);
    final lang = context.read<LanguageProvider>();
    final colors = theme.colorScheme;

    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeFont = textScaler.scale(1) > 1.3;

    return ChangeNotifierProvider(
      create: (_) => SpendingChartViewModel(
        context.read<MonthlyTransactionRepository>(),
        context.read<CategoryRepository>(),
      ),
      builder: (context, child) {
        final vm = context.watch<SpendingChartViewModel>();

        if (vm.isLoading) {
          return const Center(child: LoadingState());
        }

        if (vm.errorMessage != null) {
          return _buildCardWrapper(
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
          return _buildCardWrapper(
            child: Center(
              child: _buildEmptyChartState(colors, lang)
            ),
          );
        }
        

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart Title
                Text(
                  "Monthly Spending Breakdown",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                Flex(
                  direction: isLargeFont ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // The Pie Chart
                    SizedBox(
                      height: isLargeFont ? 200 : 160,
                      width: isLargeFont ? double.infinity : 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          // Scale center space so it doesn't look tiny with big text
                          centerSpaceRadius: textScaler.scale(35),
                          sections: _buildSections(data, colors, textScaler),
                        ),
                      ),
                    ),

                    if (!isLargeFont) const SizedBox(width: 24),
                    if (isLargeFont) const SizedBox(height: 24),

                    // The Legend
                    Expanded(
                      flex: isLargeFont ? 0 : 1,
                      child: _buildLegend(data, textScaler),
                    ),
                  ],
                ),
              ],
            ),            
          ),
        );
      },
    );
        
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data, ColorScheme colors, TextScaler textScaler) {
    final totalExpenses = data.values.fold(0.0, (sum, item) => sum + item);
    int index = 0;

    return data.entries.map((entry) {
      final color = _vibrantColors[index % _vibrantColors.length];
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
            amount: entry.value,
            compact: true, 
            isExpense: true,
            positiveColor: colors.onSurface, 
            negativeColor: colors.onSurface,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          )
        : null,
        
        // Move the badge to the center of the slice (0.0 = center of donut, 1.0 = outer edge)
        badgePositionPercentageOffset: 0.55,
        );
    }).toList();
  }

  Widget _buildLegend(Map<String, double> data, TextScaler textScaler) {
    int index = 0;
    
    return Wrap(
      spacing: 16, // Horizontal gap between items
      runSpacing: 8, // Vertical gap between lines
      children: data.entries.map((entry) {
        final color = _vibrantColors[index % _vibrantColors.length];
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

  Widget _buildCardWrapper({required Widget child}) {
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

  Widget _buildEmptyChartState(ColorScheme colors, LanguageProvider lang) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedEmptyChart(
              message: lang.translate('No data recorded').toUpperCase(),
            ),
          ],
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