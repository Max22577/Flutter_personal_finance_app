import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import '../../../models/category.dart';
import '../../../models/transaction.dart';
import 'transaction_history/state/empty_state.dart';
import 'transaction_history/state/error_state.dart';
import 'transaction_history/state/loading_state.dart';
import 'transaction_history/transaction_group.dart';


final FirestoreService _firestoreService = FirestoreService.instance;

class TransactionHistory extends StatefulWidget {
  final User user;
  final bool isActive; 
  
  const TransactionHistory({required this.user, required this.isActive, super.key});

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _transactionSubscription;
  StreamSubscription? _categorySubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadTransactions();
    _loadCategories();
  }

  void _loadTransactions() {
    _transactionSubscription = _firestoreService.streamTransactions().listen(
      (transactions) {
        if (mounted) {
          setState(() {
            _transactions = transactions;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load transactions: $e';
            _isLoading = false;
          });
        }
      },
    );
  }

  void _loadCategories() {
    _categorySubscription = _firestoreService.streamCategories().listen(
      (categories) {
        if (mounted) {
          setState(() => _categories = categories);
        }
      },
    );
  }

  Map<DateTime, List<Transaction>> _groupByDate() {
    final Map<DateTime, List<Transaction>> groups = {};
    
    for (final transaction in _transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      groups.putIfAbsent(date, () => []).add(transaction);
    }
    
    return groups;
  }

  void _onRefresh() {
    setState(() => _isLoading = true);
    _transactionSubscription?.cancel();
    _loadTransactions();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    _categorySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingState();
    if (_errorMessage != null) return ErrorState(message: _errorMessage!);
    if (_transactions.isEmpty) return EmptyState(isActive: widget.isActive);

    // Group transactions by date
    final dateGroups = _groupByDate();
    final sortedDates = dateGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async => _onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final transactions = dateGroups[date]!;
          
          return TransactionGroupWidget(
            date: date,
            transactions: transactions,
            categories: _categories,
            user: widget.user,
            onDelete: (transaction) => _showDeleteDialog(context, transaction),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Transaction transaction) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete "${transaction.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      
      try {
        await _firestoreService.deleteTransaction(transaction.id!);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Deleted "${transaction.title}"',
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
            content: Text('Delete failed: $e',
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