import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/category.dart';
import '../transaction_form.dart';
import 'transaction_tile.dart';

class TransactionGroupWidget extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final List<Category> categories;
  final User user;
  final Function(Transaction) onDelete;

  const TransactionGroupWidget({
    required this.date,
    required this.transactions,
    required this.categories,
    required this.user,
    required this.onDelete,
    super.key,
  });

  String _getCategoryName(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Uncategorized';
  }

  String _formatDateHeader() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, yesterday)) return 'Yesterday';
    
    return DateFormat('EEEE, MMMM d').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showEditForm(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => TransactionForm(
        user: user,
        transactionToEdit: transaction,
      ),
    ).then((updatedTransaction) {
      // Optional: Handle any callback when form closes
      if (updatedTransaction != null) {
        // Transaction was updated, you could refresh or show confirmation
        debugPrint('Transaction updated: $updatedTransaction');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            _formatDateHeader(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        // Transaction Tiles
        ...transactions.map((transaction) => TransactionTile(
              transaction: transaction,
              categoryName: _getCategoryName(transaction.categoryId),
              onEdit: () => _showEditForm(context, transaction),
              onDelete: () => onDelete(transaction),
            )),
      ],
    );
  }
}