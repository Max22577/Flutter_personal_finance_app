import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/widgets/shared/raised_floating_action_button.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';
import '../core/widgets/transactions/transaction_form.dart';
import '../core/widgets/transactions/transaction_history.dart';


class TransactionsPage extends StatefulWidget {
  final bool isActive;
  
  const TransactionsPage({required this.isActive, super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late NavigationProvider _navigationProvider;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAppBar(context);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigationProvider = context.read<NavigationProvider>();
    _navigationProvider.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (!mounted) return;
    final nav = context.read<NavigationProvider>();
    
    if (nav.selectedIndex == 1 && nav.currentActions.isEmpty) {
      _updateAppBar(context);
    } 
  }

  void _updateAppBar(BuildContext context) {
      if (!mounted) return;
      final nav = context.read<NavigationProvider>();
      
      if (nav.selectedIndex == 1) {
        nav.setActions([
          IconButton(
            key: const ValueKey('_transaction_add'), 
            icon: const Icon(Icons.add),
            onPressed: () => _showTransactionForm(context),
          ),
        ]);
      }
  }

  void _showTransactionForm(BuildContext context, {Transaction? transaction}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      elevation: 0,                       
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => TransactionForm(user: user, transactionToEdit: transaction),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final nav = context.read<NavigationProvider>();
        nav.setActions([]);
      }
    });
    _navigationProvider.removeListener(_onNavChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please sign in to view transactions."));
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      body: TransactionHistory(user: user, isActive: widget.isActive),
      
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transaction_add',
        onPressed: () => _showTransactionForm(context),
        icon:  Icon(Icons.add, key: const ValueKey('add_transaction'), color: colors.onSurface),
        label: Text(lang.translate('new_transaction'), style: theme.textTheme.labelLarge),
        elevation: 4, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.2)), 
        ),
        backgroundColor: colors.primaryContainer,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: const RaisedFloatingActionButtonLocation(),
    );
  }
}