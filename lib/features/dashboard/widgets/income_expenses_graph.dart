import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/features/transactions/pages/transactions.dart';
import 'package:personal_fin/models/daily_finance_data.dart';
import 'package:provider/provider.dart';
import '../view_models/graph_view_model.dart';

class IncomeExpensesGraph extends StatelessWidget {
  final int daysToShow;
  final double height;

  const IncomeExpensesGraph({this.daysToShow = 7, this.height = 250, super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => GraphViewModel(
        repo: context.read<TransactionRepository>(),
      )..loadData(daysToShow),
      child: Consumer<GraphViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) return _buildLoadingState(height);
          if (vm.errorMessage != null) return _buildErrorState(vm, height, lang);
          if (vm.dailyData.isEmpty) return _buildEmptyState(context, theme, lang);
                    
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${lang.translate('income_vs_expenses')} ($daysToShow ${lang.translate('days')})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),   
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: height,
                child: LineChart(_buildChartData(vm, theme, context)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(double height) {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(GraphViewModel vm, double height, LanguageProvider lang) {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            vm.errorMessage ?? lang.translate('error_loading_graph'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => vm.loadData(daysToShow),
            child: Text(lang.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, theme, LanguageProvider lang, {bool isActive = true}) {
    final colors = theme.colorScheme;

    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with a soft background
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.auto_graph_rounded, color: colors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            lang.translate('no_activity_yet'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            lang.translate('add_transactions_description'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          // A CTA button to encourage interaction
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionsPage(isActive: isActive))),
            icon: const Icon(Icons.add, size: 18),
            label: Text(lang.translate('add_transaction')),
          ),
        ],
      ),
    );
  }
  
  LineChartData _buildChartData(GraphViewModel vm, ThemeData theme, BuildContext context) {
    final colors = theme.colorScheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final maxY = vm.calculateMaxValue();
    final cf = context.watch<CurrencyProvider>().formatter;
    final lang = context.watch<LanguageProvider>();

    return LineChartData(
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colors.outlineVariant.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35, 
          getTitlesWidget: (value, meta) {
            String text;
            if (value >= 1000) {
              text = '${(value / 1000).toStringAsFixed(1)}K';
            } else {
              text = value.toInt().toString();
            }
            
            return SideTitleWidget(
              meta: meta, 
              child: Text(
                text,
                style: theme.textTheme.labelSmall?.copyWith(color: colors.outline),
              ),
            );
          },
        ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: daysToShow > 7 ? 5 : 1, 
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= vm.dailyData.length) return const SizedBox();
              final date = vm.dailyData[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat(daysToShow <= 7 ? 'E' : 'MMM d', lang.localeCode).format(date),
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.outline),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isIncome = spot.barIndex == 0;
              return LineTooltipItem(
                '${isIncome ? lang.translate('income') : lang.translate('expense')}\n',
                theme.textTheme.bodyMedium!.copyWith(
                  color: isIncome ? financialColors.income : financialColors.expense,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: _formatCurrencyValue(spot.y, cf, compact: true, lang),
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        _generateLineData(true, financialColors.income, vm.dailyData),
        _generateLineData(false, financialColors.expense, vm.dailyData),
      ],
    );
  }

  // Synchronous formatting helper using cached currency
  String _formatCurrencyValue(double value, CurrencyFormatter formatter, LanguageProvider lang, {bool compact = false}) {
    // Use the built-in logic from your new CurrencyFormatter class
    if (compact) {
      return formatter.formatCompact(value, lang.localeCode);
    }
    
    return formatter.format(value, lang.localeCode);
  }

  LineChartBarData _generateLineData(bool isIncome, Color color, List<DailyFinanceData> dailyData) {
    return LineChartBarData(
      spots: _generateSpots(isIncome, dailyData),
      isCurved: true,
      preventCurveOverShooting: true,
      preventCurveOvershootingThreshold: 0,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: false,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.01)],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(bool forIncome, List<DailyFinanceData> dailyData) {
    return List.generate(dailyData.length, (i) {
      final value = forIncome ? dailyData[i].income : dailyData[i].expenses;
      return FlSpot(i.toDouble(), value);
    });
  }
}