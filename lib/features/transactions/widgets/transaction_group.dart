import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_form.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import 'transaction_tile.dart';

class TransactionGroupWidget extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final List<Category> categories;
  final Function(Transaction) onDelete;

  const TransactionGroupWidget({
    required this.date,
    required this.transactions,
    required this.categories,
    required this.onDelete,
    super.key,
  });

  String _getCategoryName(String categoryId, LanguageProvider lang) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return lang.translate('uncategorized');
  }

  String _formatDateHeader(LanguageProvider lang) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (_isSameDay(date, today)) return lang.translate('today');
    if (_isSameDay(date, yesterday)) return lang.translate('yesterday');
    
    return DateFormat('EEEE, MMMM d', lang.localeCode).format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showEditForm(BuildContext context, Transaction transaction, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => TransactionForm(
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
    final lang = context.read<LanguageProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            _formatDateHeader(lang),
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
              categoryName: _getCategoryName(transaction.categoryId, lang),
              onEdit: () => _showEditForm(context, transaction, lang),
              onDelete: () => onDelete(transaction),
            )),
      ],
    );
  }
}