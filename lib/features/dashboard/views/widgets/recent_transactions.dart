import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/features/dashboard/views/widgets/recent_transactions/transaction_display.dart';
import 'package:personal_fin/features/dashboard/views/widgets/recent_transactions/transaction_item.dart';
import 'package:provider/provider.dart';
import '../../view_models/recent_transactions_view_model.dart';
class RecentTransactions extends StatelessWidget {
  final int maxItems;
  final VoidCallback? onViewAll;

  const RecentTransactions({
    this.maxItems = 5,
    this.onViewAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();

    return Provider(
      create: (context) => RecentTransactionsViewModel(
        repo: context.read<TransactionRepository>(),
        catRepo: context.read<CategoryRepository>(),
        currencyProvider: context.read<CurrencyProvider>(),
        exchangeService: context.read<ExchangeRateService>(),
        maxItems: maxItems,
      ),
      child: Builder(
        builder: (context) {
          final vm = context.read<RecentTransactionsViewModel>();

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, lang, textScaler),
                  const SizedBox(height: 12),
                  // 2. The StreamBuilder now handles all loading/error/data states
                  _buildContent(vm, theme, lang, textScaler),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, LanguageProvider lang, TextScaler textScaler) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          lang.translate('recent_transactions'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              lang.translate('view_all'),
              style: TextStyle(fontSize: textScaler.scale(14))),
          ),
      ],
    );
  }

  Widget _buildContent(RecentTransactionsViewModel vm, ThemeData theme, LanguageProvider lang, TextScaler textScaler) {
    return StreamBuilder<List<TransactionDisplay>>(
      stream: vm.recentTransactionsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        
        final displayList = snapshot.data!;

        if (displayList.isEmpty) {
          return _buildEmptyState(theme, lang, textScaler);
        }
        
        return Column(
          children: displayList.map((item) => TransactionItem(
            transaction: item.tx, 
            categoryName: item.categoryName, 
            showDate: true,
            showCategory: true,
          )).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, LanguageProvider lang, TextScaler textScaler) {
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: textScaler.scale(40), color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            lang.translate('no_recent_transactions'),
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),   
    );
  }
}