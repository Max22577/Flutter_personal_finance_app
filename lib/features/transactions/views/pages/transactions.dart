import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/features/transactions/views/widgets/transaction_form.dart';
import 'package:personal_fin/features/transactions/views/widgets/transaction_history.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  @override
  void initState() {
    super.initState();
    _updateAppBar();
  }


  void _updateAppBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NavigationProvider>().setActions([
          _AppBarAddButton(onPressed: () => _showTransactionForm(context)),
        ]);
      }
    });
  }

  void _showTransactionForm(BuildContext context, {Transaction? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => TransactionForm(transactionToEdit: transaction),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NavigationProvider>().setActions([]);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: TransactionHistory(),
      floatingActionButton: _AddTransactionFAB(
        onPressed: () => _showTransactionForm(context),
        label: lang.translate('new_transaction'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}


class _AppBarAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AppBarAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: const Icon(Icons.add),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _AddTransactionFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _AddTransactionFAB({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FloatingActionButton.extended(
      heroTag: 'transaction_add',
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label, style: theme.textTheme.labelLarge),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer, // Fixed: Use theme-appropriate color
    );
  }
}