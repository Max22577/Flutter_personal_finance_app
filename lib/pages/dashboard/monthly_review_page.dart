import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/services/monthly_data_service.dart';
import 'package:personal_fin/core/widgets/dashboard/monthly_review.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';

class MonthlyReviewPage extends StatefulWidget {
  final DateTime? month;
  final String? customTitle;

  const MonthlyReviewPage({
    this.month,
    this.customTitle,
    super.key,
  });

  @override
  State<MonthlyReviewPage> createState() => _MonthlyReviewPageState();
}

class _MonthlyReviewPageState extends State<MonthlyReviewPage> {
  late Future<MonthlyData> _monthlyDataFuture;
  late Future<MonthlyData?> _previousMonthDataFuture;
  final MonthlyDataService _service = MonthlyDataService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final month = widget.month ?? DateTime.now();
    final previousMonth = DateTime(month.year, month.month - 1, 1);

    setState(() {
      _monthlyDataFuture = _service.getMonthlyData(month);
      _previousMonthDataFuture = _service.getMonthlyData(previousMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();
    

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(lang.translate('monthly_review_title'), 
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onPrimary,
          ),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        centerTitle: true, 
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.onPrimary),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: Future.wait([_monthlyDataFuture, _previousMonthDataFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        lang.translate('err_load_monthly'),
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: .6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text(lang.translate('try_again')),
                      ),
                    ],
                  ),
                ),
              );
            }

            final monthlyData = snapshot.data![0] as MonthlyData;
            final previousMonthData = snapshot.data![1];

            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    MonthlyReview(
                      monthlyData: monthlyData,
                      previousMonthData: previousMonthData,
                      onTap: () => _showMonthlyDetails(context, monthlyData),
                    ),
                    const SizedBox(height: 24),
                    _buildAdditionalInsights(context, monthlyData),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdditionalInsights(BuildContext context, MonthlyData data) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    // Calculate Savings Rate: (Net / Income) * 100
    final savingsRate = data.income > 0 ? (data.net / data.income).clamp(0.0, 1.0) : 0.0;

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('visual_breakdown'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Horizontal Row for Gauge and Core Stat
            Row(
              children: [
                // Savings Rate Gauge
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.all(16),
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: savingsRate,
                            strokeWidth: 8,
                            backgroundColor: colors.primary.withValues(alpha: 0.1),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${(savingsRate * 100).toInt()}%', 
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                            Text(lang.translate('saved_label'), style: theme.textTheme.labelSmall),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Total Transactions Box
                Expanded(
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, color: colors.primary),
                        const SizedBox(height: 8),
                        Text('${data.transactionCount}', 
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                        Text(lang.translate('items_label'), style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          
            
            const SizedBox(height: 24),
            
            // Top Spending Categories Card
            Container(
              padding: const EdgeInsets.all(20),
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
                  Text(lang.translate('top_spending'), style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold, letterSpacing: 1.1, color: colors.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  if (data.categoryBreakdown.isEmpty)
                    Text(lang.translate('no_spending_data'))
                  else
                    ...data.categoryBreakdown.entries
                        .toList()
                        .sorted((a, b) => b.value.compareTo(a.value)) // Sort by highest spending
                        .reversed
                        .take(3)
                        .map((e) => _buildSpendingBar(
                              e.key, 
                              e.value, 
                              data.expenses, 
                              colors.primary, 
                              theme,
                              lang,
                            )),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildSpendingBar(String category, double amount, double total, Color color, ThemeData theme, LanguageProvider lang) {
    final percentage = total > 0 ? amount / total : 0.0;
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.translate(category), style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              CurrencyDisplay(amount: amount, isExpense: true, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$monthName ${lang.translate('summary_title')}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(lang.translate('income_label'), '\$${data.income.toStringAsFixed(2)}', financialColors.income),
            _buildDetailRow(lang.translate('expenses_label'), '\$${data.expenses.toStringAsFixed(2)}', financialColors.expense),
            const Divider(),
            _buildDetailRow(lang.translate('net_profit'), '\$${data.net.toStringAsFixed(2)}', theme.colorScheme.primary),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('close_btn')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}