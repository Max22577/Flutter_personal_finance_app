import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/widgets/empty_state.dart';
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
    final textScaler = MediaQuery.textScalerOf(context);

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
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, lang, textScaler),
                  const SizedBox(height: 12),
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
    // Using Wrap instead of Row prevents the "View All" button from disappearing
    // or squashing the title when the system font is large.
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
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: lang.translate('error_loading'),
          message: vm.errorMessage!,
          actionText: lang.translate('retry'),
          onAction: () => vm.retry(), 
        ),
      );
    }

    if (vm.recentTransactions.isEmpty) {
      return _buildEmptyState(theme, lang, textScaler);
    }

    return Column(
      children: vm.recentTransactions.map((tx) => TransactionItem(
        transaction: tx,
        categoryName: vm.getCategoryName(tx.categoryId),
        showDate: true,
        showCategory: true,
        showTime: false,
      )).toList(),
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