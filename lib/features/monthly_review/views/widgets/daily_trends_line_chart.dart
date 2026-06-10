import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/features/monthly_review/view_model/monthly_review_view_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DailyTrendsLineChart extends StatefulWidget {
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
  State<DailyTrendsLineChart> createState() => _DailyTrendsLineChartState();
}

class _DailyTrendsLineChartState extends State<DailyTrendsLineChart> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Schedule scrolling after the widget frame is completely rendered
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentDay());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentDay() {
    if (!_scrollController.hasClients || widget.points.isEmpty) return;

    final now = DateTime.now();
    // Only center if looking at the active ongoing month
    if (widget.selectedMonth.month != now.month || widget.selectedMonth.year != now.year) {
      return;
    }

    // Determine viewport metrics
    final double viewPortWidth = MediaQuery.of(context).size.width - 72; 
    final double dayWidth = viewPortWidth / 5;
    
    // Find where the current day sits in our sparse points list index
    final currentDayIndex = widget.points.indexWhere((p) => p.day == now.day);
    
    if (currentDayIndex != -1) {
      // Position of target day element from the left side of the canvas
      final dayPosition = currentDayIndex * dayWidth;
      
      // Target offset shifts the element to the direct center of the screen
      final targetOffset = dayPosition - (viewPortWidth / 2) + (dayWidth / 2);

      // Clamp the offset to make sure it doesn't scroll past boundaries
      final maxScroll = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = context.watch<LanguageProvider>().localeCode;

    if (widget.points.isEmpty) return const SizedBox.shrink();

    // Calculate Dynamic Y-Axis scale bounds
    double maxVal = 100.0;
    for (var p in widget.points) {
      if (p.income > maxVal) maxVal = p.income;
      if (p.expenses > maxVal) maxVal = p.expenses;
    }
    final maxY = maxVal * 1.2;

    // High-contrast neon pairs for deep container backgrounds
    final incomeLineColor = Colors.greenAccent.shade400;
    final expenseLineColor = Colors.orangeAccent.shade200;

    final double viewPortWidth = MediaQuery.of(context).size.width - 72; 
    final double dayWidth = viewPortWidth / 5; 
    final double chartWidth = widget.points.length * dayWidth;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // FIXED Y-AXIS
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
                          widget.currencyFormatter.formatCompact(value, locale),
                          style: TextStyle(fontSize: 8, color: colors.onPrimaryContainer),
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
              controller: _scrollController, 
              scrollDirection: Axis.horizontal,
              reverse: false, 
              child: SizedBox(
                width: chartWidth,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.15),
                        strokeWidth: 0.5,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.1),
                        strokeWidth: 0.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final int dayIdx = value.toInt() - 1;
                            if (dayIdx < 0 || dayIdx >= widget.points.length) return const SizedBox.shrink();
                            
                            final pointDay = widget.points[dayIdx].day;
                            final isToday = pointDay == DateTime.now().day && 
                                            widget.selectedMonth.month == DateTime.now().month;

                            final dateForPoint = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, pointDay);
                            
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                DateFormat('MMM d').format(dateForPoint),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  // Emphasize the current day's label text color
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? colors.primary : colors.onPrimaryContainer.withValues(alpha: 0.7),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 1,
                    maxX: 30,
                    minY: 0,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => colors.surfaceContainerHigh,
                        fitInsideVertically: true,
                        fitInsideHorizontally: true,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final int dayIdx = spot.x.toInt() - 1;
                            if (dayIdx < 0 || dayIdx >= widget.points.length) return null;
                            final pt = widget.points[dayIdx];

                            final isIncome = spot.barIndex == 0; 
                            final value = isIncome ? pt.income : pt.expenses;
                            final label = isIncome ? 'Income' : 'Expenses';
                            final color = isIncome ? incomeLineColor : expenseLineColor;

                            return LineTooltipItem(
                              '$label: ${widget.currencyFormatter.formatDisplay(value, locale)}',
                              TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Income Line
                      LineChartBarData(
                        spots: widget.points.asMap().entries.map((e) => FlSpot((e.key + 1).toDouble(), e.value.income)).toList(),
                        isCurved: true,
                        curveSmoothness: 0.2,
                        color: incomeLineColor,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                      // Expenses Line
                      LineChartBarData(
                        spots: widget.points.asMap().entries.map((e) => FlSpot((e.key + 1).toDouble(), e.value.expenses)).toList(),
                        isCurved: true,
                        curveSmoothness: 0.2,
                        color: expenseLineColor,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              expenseLineColor.withValues(alpha: 0.2),
                              expenseLineColor.withValues(alpha: 0.0),
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
        ],
      ),
    );
  }
}