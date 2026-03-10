import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:personal_fin/features/dashboard/view_models/monthly_review_view_model.dart';
import 'package:personal_fin/features/dashboard/widgets/monthly_review.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';

class MonthlyReviewPage extends StatelessWidget {
  final DateTime? month;
  final String? customTitle;

  const MonthlyReviewPage({this.month, this.customTitle, super.key});

  @override
  Widget build(BuildContext context) {
    final targetMonth = month ?? DateTime.now();

    return ChangeNotifierProvider(
      create: (_) => MonthlyReviewViewModel(MonthlyDataRepository())..loadData(targetMonth),
      child: Consumer<MonthlyReviewViewModel>(
        builder: (context, vm, _) {
          final lang = context.watch<LanguageProvider>();
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final text = theme.textTheme;

          return Scaffold(
            backgroundColor: colors.surfaceContainerLow,
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
            body: _buildBody(context, vm, lang, targetMonth, colors, text),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MonthlyReviewViewModel vm, LanguageProvider lang, DateTime month, ColorScheme colors, TextTheme text) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return _errorState(lang, colors, text, message: vm.errorMessage!, onRetry: () => vm.loadData(month));
    }

    if (vm.currentMonthData == null) { 
      return const Center(child: Text("No data found for this month"));
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadData(month),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            MonthlyReview(
              monthlyData: vm.currentMonthData!,
              previousMonthData: vm.previousMonthData,
              onTap: () => _showMonthlyDetails(context, vm.currentMonthData!),
            ),
            const SizedBox(height: 24),
            _buildAdditionalInsights(context, vm, lang, colors, text),
          ],
        ),
      ),
    );
  }

  Widget _errorState(LanguageProvider lang, ColorScheme colors, TextTheme text, {required String message, required Function onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
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
              onPressed: () => onRetry,
              child: Text(lang.translate('try_again')),
            ),
          ],
        ),
      ),
    );
  }

  // UI helper for insights using ViewModel values
  Widget _buildAdditionalInsights(BuildContext context, MonthlyReviewViewModel vm, LanguageProvider lang, ColorScheme colors, TextTheme text) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.translate('visual_breakdown'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
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
                        value: vm.savingsRate,
                        strokeWidth: 8,
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(vm.savingsRate * 100).toInt()}%', 
                          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        Text(lang.translate('saved_label'), style: text.labelSmall),
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
                    Text('${vm.currentMonthData!.transactionCount}', 
                      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    Text(lang.translate('items_label'), style: text.labelSmall),
                  ],
                ),
              ),
            ),            
          ],
        ),
        const SizedBox(height: 24),
        _topSpendingCard(vm, vm.currentMonthData!.expenses, colors, text, lang),
      ],
    );
  }

  Widget _topSpendingCard(MonthlyReviewViewModel vm,  double expenses, ColorScheme colors, TextTheme text, LanguageProvider lang) {
    final categories = vm.topSpendingCategories;

    return Container(
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
          Text(lang.translate('top_spending'), style: text.labelMedium?.copyWith(
            fontWeight: FontWeight.bold, letterSpacing: 1.1, color: colors.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Text(lang.translate('no_spending_data'))
          else
            ...categories.map((e) => _buildSpendingBar(
              e.key, 
              e.value, 
              vm.currentMonthData!.expenses , 
              colors.primary, 
              colors,
              text,
              lang,
            )),
        ],
      ),
    );
  }
  Widget _buildSpendingBar(String category, double amount, double total, Color color, ColorScheme colors, TextTheme text, LanguageProvider lang) {
    final percentage = total > 0 ? amount / total : 0.0;
  
    
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