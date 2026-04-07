import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/features/dashboard/widgets/transaction_item.dart';
import 'package:provider/provider.dart';
import '../view_models/recent_transactions_view_model.dart';

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
    return ChangeNotifierProvider(
      create: (context) => RecentTransactionsViewModel(
        repo: context.read<TransactionRepository>(),
        maxItems: maxItems,
      ),
      child: Consumer<RecentTransactionsViewModel>(
        builder: (context, vm, _) {
          final theme = Theme.of(context);
          final lang = context.watch<LanguageProvider>();

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, lang),
                  const SizedBox(height: 12),
                  _buildContent(vm, theme, lang),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          lang.translate('recent_transactions'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(lang.translate('view_all')),
          ),
      ],
    );
  }

  Widget _buildContent(RecentTransactionsViewModel vm, ThemeData theme, LanguageProvider lang) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.recentTransactions.isEmpty) {
      return _buildEmptyState(theme, lang);
    }

    return Column(
      children: vm.recentTransactions.map((tx) => TransactionItem(
        transaction: tx,
        showDate: true,
        showCategory: true,
        showTime: false,
      )).toList(),
    );
  }

  Widget _buildEmptyState(ThemeData theme, LanguageProvider lang) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 40, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text(
              lang.translate('no_recent_transactions'),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}