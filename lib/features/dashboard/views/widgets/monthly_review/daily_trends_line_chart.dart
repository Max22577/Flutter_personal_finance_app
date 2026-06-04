import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/features/dashboard/view_models/monthly_review_view_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DailyTrendsLineChart extends StatelessWidget {
  final List<DailyChartPoint> points;
  final DateTime selectedMonth;
  final CurrencyFormatter currencyFormatter;

  const DailyTrendsLineChart({
    required this.points, 
    required this.selectedMonth,
    required this.currencyFormatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.watch<LanguageProvider>().localeCode;

    if (points.isEmpty) return const SizedBox.shrink();

    // Calculate Dynamic Y-Axis scale and formatting bounds
    double maxVal = 100.0;
    for (var p in points) {
      if (p.income > maxVal) maxVal = p.income;
      if (p.expenses > maxVal) maxVal = p.expenses;
    }
    final maxY = maxVal * 1.2;

    final incomeLineColor = Colors.greenAccent.shade400;
    final expenseLineColor = Colors.redAccent.shade400;

    // Set up horizontal scrolling dimensions
    // 5 days visible at once means each day gets roughly (screenWidth / 5) pixels
    final double viewPortWidth = MediaQuery.of(context).size.width - 72; // Accounting for card padding
    final double dayWidth = viewPortWidth / 5; 
    final double chartWidth = points.length * dayWidth;

    return Row(
      children: [
        // FIXED Y-AXIS (Never scrolls)
        SizedBox(
          width: 40,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: (maxY / 4).floorToDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value >= meta.max) return const SizedBox.shrink();
                      return Text(
                        currencyFormatter.formatCompact(value, locale),
                        style: const TextStyle(fontSize: 8),
                        textAlign: TextAlign.right,
                      );
                    },
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY,
            ),
          ),
        ),
        
        // SCROLLING CHART AREA
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Starts scrolled to the end of the month (most recent dates)
            child: SizedBox(
              width: chartWidth,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 0.5,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true, // Master toggle for titles
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    
                    // ENABLE AND CONFIGURE Y-AXIS TITLES
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: 40, // INCREASED: Gives space for the "$1.2k" text
                        interval: (maxY / 4).floorToDouble(), // Dynamic interval based on your data scale
                        getTitlesWidget: (value, meta) {
                          // Return nothing if it's the 0 baseline or too close to the top
                          if (value == 0 || value >= meta.max) return const SizedBox.shrink();

                          return Text(
                            currencyFormatter.formatCompact(value, locale), 
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final int dayIdx = value.toInt() - 1;
                          if (dayIdx < 0 || dayIdx >= points.length) return const SizedBox.shrink();
                          
                          final dateForPoint = DateTime(selectedMonth.year, selectedMonth.month, points[dayIdx].day);
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              DateFormat('MMM d').format(dateForPoint),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  ),
                  borderData: FlBorderData(show: false),
                  minX: 1,
                  maxX: points.length.toDouble(),
                  minY: 0,
                  maxY: maxY,
                  
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) => TouchedSpotIndicatorData(
                        const FlLine(color: Colors.transparent), 
                        const FlDotData(show: true),
                      )).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => theme.colorScheme.surfaceContainerHigh,
                      fitInsideVertically: true, // Prevents clipping at the top
                      fitInsideHorizontally: true, // Prevents clipping at the sides
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        // We need to return an item for each spot (Income and Expenses)
                        return touchedSpots.map((spot) {
                          final int dayIdx = spot.x.toInt() - 1;
                          if (dayIdx < 0 || dayIdx >= points.length) return null;
                          final pt = points[dayIdx];

                          // Identify which line this spot belongs to
                          final isIncome = spot.barIndex == 0; 
                          final value = isIncome ? pt.income : pt.expenses;
                          final label = isIncome ? 'Income' : 'Expenses';
                          final color = isIncome ? incomeLineColor : expenseLineColor;

                          return LineTooltipItem(
                            '$label: ${currencyFormatter.formatDisplay(value, locale)}',
                            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  
                  lineBarsData: [
                    // Income Line (Thinner)
                    LineChartBarData(
                      spots: points.map((p) => FlSpot(p.day.toDouble(), p.income)).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: incomeLineColor,
                      barWidth: 1.5, // Thinner profile
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                    
                    // Expenses Line (Thinner with fading area block)
                    LineChartBarData(
                      spots: points.map((p) => FlSpot(p.day.toDouble(), p.expenses)).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: expenseLineColor,
                      barWidth: 1.5, // Thinner profile
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            expenseLineColor.withValues(alpha: 0.15),
                            expenseLineColor.withValues(alpha: 0.00),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]
    );
  }
}