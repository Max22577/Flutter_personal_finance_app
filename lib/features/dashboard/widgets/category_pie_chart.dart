import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
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
    final colors = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => SpendingChartViewModel(
        context.read<MonthlyTransactionRepository>(),
        context.read<CategoryRepository>(),
      ),
      child: Consumer<SpendingChartViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator());
          
          final data = vm.categoryData;
          if (data.isEmpty) return const Center(child: Text("No expenses this month"));

         return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Chart Title
                  const Text(
                    "Monthly Spending Breakdown",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // 2. The Pie Chart
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: _buildSections(data, colors),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. The Legend
                  _buildLegend(data),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data, ColorScheme colors) {
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
        radius: 50,
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
        
        // 3. Move the badge to the center of the slice (0.0 = center of donut, 1.0 = outer edge)
        badgePositionPercentageOffset: 0.55,
        );
    }).toList();
  }

  Widget _buildLegend(Map<String, double> data) {
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
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              entry.key,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }).toList(),
    );
  }
}