import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/features/transactions/widgets/state/empty_state.dart';
import 'package:personal_fin/features/transactions/widgets/state/error_state.dart';
import 'package:personal_fin/features/transactions/widgets/state/loading_state.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_group.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';

class TransactionHistory extends StatelessWidget {
  final User user;
  final bool isActive;
  
  const TransactionHistory({required this.user, required this.isActive, super.key});

  @override
  Widget build(BuildContext context) {
    // Access the brain
    final vm = context.watch<TransactionViewModel>();
    final lang = context.read<LanguageProvider>();

    if (vm.isLoading) return const LoadingState();
    if (vm.errorMessage != null) return ErrorState(message: vm.errorMessage!);
    if (vm.transactions.isEmpty) return EmptyState(isActive: isActive);

    final dateGroups = vm.groupedTransactions;
    final sortedDates = dateGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        return TransactionGroupWidget(
          date: date,
          user: user,
          transactions: dateGroups[date]!,
          categories: vm.categories,
          onDelete: (tx) => _confirmDelete(context, vm, tx, lang),
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
        await vm.deleteTransaction(tx.id!);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${lang.translate('deleted')} "${tx.title}"',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer)
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${lang.translate('delete_failed')}: $e',
              style: TextStyle(color: theme.colorScheme.onErrorContainer)
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.errorContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }
}