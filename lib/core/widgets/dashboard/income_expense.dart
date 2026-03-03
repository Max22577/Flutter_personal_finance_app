import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:provider/provider.dart';
import '../../../models/currency.dart';
import '../../../models/daily_finance_data.dart';

final FirestoreService _firestoreService = FirestoreService.instance;

class IncomeExpensesGraph extends StatefulWidget {
  final int daysToShow; 
  final double height;

  const IncomeExpensesGraph({
    this.daysToShow = 7,
    this.height = 250,
    super.key,
  });

  @override
  State<IncomeExpensesGraph> createState() => _IncomeExpensesGraphState();
}

class _IncomeExpensesGraphState extends State<IncomeExpensesGraph> {
  List<DailyFinanceData> _dailyData = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _transactionSubscription;

  Currency? _currentCurrency;

  @override
  void initState() {
    super.initState();
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    _currentCurrency = currencyProvider.currency;
    _loadData();
  }

  void _loadData() {
    _transactionSubscription = _firestoreService.streamTransactions().listen(
      (transactions) {
        _processTransactions(transactions);
      },
      onError: (e) {
        setState(() {
          _errorMessage = 'Failed to load graph data: $e';
          _isLoading = false;
        });
      },
    );
  }

  void _processTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoffDate = today.subtract(Duration(days: widget.daysToShow));

    // Initialize map with empty data for the range
    final Map<String, DailyFinanceData> dataMap = {};
    for (int i = widget.daysToShow - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dataMap[dateKey] = DailyFinanceData.empty(date);
    }

    // Process only transactions within the window
    for (final t in transactions) {
      if (t.date.isBefore(cutoffDate)) continue;
      
      final dateKey = DateFormat('yyyy-MM-dd').format(t.date);
      if (dataMap.containsKey(dateKey)) {
        dataMap[dateKey] = dataMap[dateKey]!.addTransaction(t.amount, t.type);
      }
    }

    final sortedData = dataMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));

    if (mounted) {
      setState(() {
        _dailyData = sortedData;
        _isLoading = false;
      });
    }
  }

  // Synchronous formatting helper using cached currency
  String _formatCurrencyValue(double value, CurrencyFormatter formatter, LanguageProvider lang, {bool compact = false}) {
    // Use the built-in logic from your new CurrencyFormatter class
    if (compact) {
      return formatter.formatCompact(value, lang.localeCode);
    }
    
    return formatter.format(value, lang.localeCode);
  }

  LineChartData _buildChartData(ThemeData theme) {
    final colors = theme.colorScheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final maxY = _calculateMaxValue();
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
            interval: widget.daysToShow > 7 ? 5 : 1, 
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _dailyData.length) return const SizedBox();
              final date = _dailyData[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat(widget.daysToShow <= 7 ? 'E' : 'MMM d', lang.localeCode).format(date),
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
        _generateLineData(true, financialColors.income),
        _generateLineData(false, financialColors.expense),
      ],
    );
  }

  LineChartBarData _generateLineData(bool isIncome, Color color) {
    return LineChartBarData(
      spots: _generateSpots(isIncome),
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

  List<FlSpot> _generateSpots(bool forIncome) {
    return List.generate(_dailyData.length, (i) {
      final value = forIncome ? _dailyData[i].income : _dailyData[i].expenses;
      return FlSpot(i.toDouble(), value);
    });
  }

  double _calculateMaxValue() {
    double max = 100;
    for (var data in _dailyData) {
      if (data.income > max) max = data.income;
      if (data.expenses > max) max = data.expenses;
    }
    return (max * 1.2); // 20% head room
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(LanguageProvider lang) {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? lang.translate('error_loading_graph'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadData,
            child: Text(lang.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 50,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            lang.translate('no_transaction_data_yet'),
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            lang.translate('add_transactions_to_see_income_vs_expenses'),
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState(lang);
    if (_dailyData.isEmpty) return _buildEmptyState(lang);

    final theme = Theme.of(context);
    final colors = theme.colorScheme;   
    final symbol = _currentCurrency?.symbol ?? '\$';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title and Legend Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${lang.translate('income_vs_expenses')} (${widget.daysToShow} ${lang.translate('days')})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),   
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // 2. The Chart Container
        SizedBox(
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: Row(
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    '${lang.translate('amount')} ($symbol)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LineChart(_buildChartData(theme)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  } 
}