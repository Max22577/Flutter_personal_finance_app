import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:personal_fin/core/shared_widgets/animated_empty_state.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:personal_fin/features/transactions/views/widgets/transaction_history/state/error_state.dart';
import 'package:personal_fin/features/transactions/views/widgets/transaction_history/transaction_group.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';

class TransactionHistory extends StatelessWidget { 
  
  const TransactionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TransactionViewModel>();
    final lang = context.read<LanguageProvider>();

    return StreamBuilder<List<Transaction>>(
      stream: vm.localizedTransactionsStream, 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(message: snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: AnimatedEmptyState(
              message: 'No transactions yet'.toUpperCase(),
              imagePath: 'assets/images/trans_wallet_light1.svg',
              darkImagePath: 'assets/images/trans_wallet_dark.svg',
              animationType: EmptyStateAnimation.bounce,
            ),
          );
        }

        final dateGroups = vm.groupTransactions(transactions);
        final sortedDates = dateGroups.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            return TransactionGroupWidget(
              date: date,
              transactions: dateGroups[date]!,
              categories: vm.categories, 
              onDelete: (tx) => _confirmDelete(context, vm, tx, lang),
            );
          },
        );
      },
    );
  }

  // Keep UI-only logic (Dialogs) in the view
  void _confirmDelete(BuildContext context, TransactionViewModel vm, Transaction tx, LanguageProvider lang) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    // ... showDialog logic ...
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('delete_transaction')),
        content: Text('Delete "${tx.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      
      try {
        await vm.deleteTransaction(tx.id);
        AppFeedback.show(messenger,'${lang.translate('deleted')} "${tx.title}"', colors: theme.colorScheme, textTheme: theme.textTheme, isError: false);
         
      } catch (e) {
        AppFeedback.show(messenger,'${lang.translate('delete_failed')}: $e', colors: theme.colorScheme, textTheme: theme.textTheme, isError: false);

      }
    }
  }
}