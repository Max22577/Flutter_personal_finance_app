import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';
import 'transaction_item.dart';

final FirestoreService _firestoreService = FirestoreService.instance;

class RecentTransactions extends StatefulWidget {
  final int maxItems;
  final VoidCallback? onViewAll;

  const RecentTransactions({
    this.maxItems = 5,
    this.onViewAll,
    super.key,
  });

  @override
  State<RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  StreamSubscription? _transactionSubscription;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    _transactionSubscription = _firestoreService.streamTransactions().listen(
      (transactions) {
        // Sort by date (newest first) and take only recent ones
        transactions.sort((a, b) => b.date.compareTo(a.date));
        final recent = transactions.take(widget.maxItems).toList();
        
        if (mounted) {
          setState(() {
            _transactions = recent;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Error loading recent transactions: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();
    
    return Card(
      elevation: 2, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.0),
      ),
      color: colors.surface, 
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.translate('recent_transactions'),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onViewAll != null)
                  TextButton(
                    onPressed: widget.onViewAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      foregroundColor: colors.primary, // Use theme primary color
                    ),
                    child: Text(
                      lang.translate('view_all'),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: colors.primary, 
                ),
              )
            else if (_transactions.isEmpty)
              _buildEmptyState(theme, colors, textTheme, lang)
            else
              Column(
                children: _transactions
                    .map((transaction) => TransactionItem(
                          transaction: transaction,
                          showDate: true,
                          showCategory: true,
                          showTime: false,
                        ))
                    .toList(),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors, TextTheme textTheme, LanguageProvider lang) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 40,
              color: colors.onSurface.withValues(alpha: 0.3), 
            ),
            const SizedBox(height: 8),
            Text(
              lang.translate('no_recent_transactions'),
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}