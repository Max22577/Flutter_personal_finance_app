import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:personal_fin/features/monthly_review/view_model/monthly_review_view_model.dart';
import 'package:personal_fin/core/shared_widgets/empty_chart_state.dart';
import 'package:personal_fin/features/monthly_review/views/widgets/daily_trends_line_chart.dart';
import 'package:provider/provider.dart';

class MonthlyTrendsCard extends StatelessWidget {
  const MonthlyTrendsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonthlyReviewViewModel>();
    final formatter = context.watch<CurrencyProvider>().formatter;
    final theme = Theme.of(context);

    final now = DateTime.now();
    final currentOption = DateTime(now.year, now.month, 1);
    final previousOption = DateTime(now.year, now.month - 1, 1);

    final DateTime normalizedSelectedMonth = DateTime(
      vm.selectedMonth.year, 
      vm.selectedMonth.month, 
      1
    );

    return StreamBuilder<List<DailyChartPoint>>(
      stream: vm.dailyTrendStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        final pointsData = snapshot.data ?? [];

        if (pointsData.isEmpty) {
          return SizedBox(
            height: 220, 
            child: Center(
              child: EmptyChartState(
                textMessage: "No transactions found for this month.",
              ),
            ),
          );
        }
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER BAR ROW WITH INTERACTIVE TIMEFRAME DROPDOWN
                Row(
                  children: [
                    Expanded( 
                      child: Text(
                        "Monthly Trends",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis, 
                        maxLines: 1,
                      ),
                      
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<DateTime>(
                        value: normalizedSelectedMonth, 
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.primary),
                        onChanged: (DateTime? nextMonth) {
                          if (nextMonth != null) vm.changeMonth(nextMonth);
                        },
                        items: [
                          DropdownMenuItem(
                            value: currentOption,
                            child: const Text("Current Month"),
                          ),
                          DropdownMenuItem(
                            value: previousOption,
                            child: const Text("Previous Month"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),                    
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: DailyTrendsLineChart(
                    points: pointsData,
                    selectedMonth: normalizedSelectedMonth,
                    currencyFormatter: formatter,
                  ),
                ),
              ],
            ),
          ),
        );
      });
  }
}