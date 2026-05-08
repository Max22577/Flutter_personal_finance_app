import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/widgets/raised_floating_action_button.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_form.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_history.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';

class TransactionsPage extends StatefulWidget {
  final bool isActive;

  const TransactionsPage({required this.isActive, super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late NavigationProvider _navProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAppBar());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navProvider = context.read<NavigationProvider>();
    _navProvider.removeListener(_onNavChanged);
    _navProvider.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (!mounted) return;
    if (_navProvider.selectedIndex == 1 && _navProvider.currentActions.isEmpty) {
      _updateAppBar();
    }
  }

  void _initAppBar() {
    if (mounted && _navProvider.selectedIndex == 1) {
      _updateAppBar();
    }
  }

  void _updateAppBar() {
    _navProvider.setActions([
      _AppBarAddButton(onPressed: () => _showTransactionForm(context)),
    ]);
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
    _navProvider.removeListener(_onNavChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navProvider.setActions([]);
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
      body: TransactionHistory(isActive: widget.isActive),
      floatingActionButton: _AddTransactionFAB(
        onPressed: () => _showTransactionForm(context),
        label: lang.translate('new_transaction'),
      ),
      floatingActionButtonLocation: const RaisedFloatingActionButtonLocation(),
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