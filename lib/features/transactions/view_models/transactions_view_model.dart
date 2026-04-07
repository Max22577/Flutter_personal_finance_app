import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/category.dart';


class TransactionViewModel extends ChangeNotifier {
  StreamSubscription? _txsub;
  StreamSubscription? _catSub;
  final TransactionRepository _txrepo;
  final CategoryRepository _catRepo;

  // Data storage
  List<Transaction> transactions = [];
  List<Category> categories = [];
  bool isLoading = true;
  String? errorMessage;

  TransactionViewModel(this._txrepo, this._catRepo) {
    _init();
  }

  void _init() {
    // Combine both streams or listen separately
    _txsub = _txrepo.transactionsStream.listen((t) {
      transactions = t;
      isLoading = false;
      notifyListeners();
    }, onError: (e) => _handleError(e));

    _catSub = _catRepo.categoriesStream.listen((c) {
      categories = c;
      notifyListeners();
    });
  }

  // Business Logic: Grouping (Moved from UI to VM)
  Map<DateTime, List<Transaction>> get groupedTransactions {
    final Map<DateTime, List<Transaction>> groups = {};
    final sortedTx = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (var tx in sortedTx) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groups.putIfAbsent(date, () => []).add(tx);
    }
    return groups;
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _txrepo.deleteTransaction(id);
    
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic e) {
    errorMessage = e.toString();
    isLoading = false;
    notifyListeners();
  }


  bool isSaving = false;

  Future<bool> saveTransaction({
    required String title,
    required double amount,
    required String type,
    required String categoryId,
    required DateTime date,
    Transaction? existingTransaction,
  }) async {
    isSaving = true;
    notifyListeners();

    try {
      final uid = _txrepo.uid;
      final transaction = Transaction(
        id: existingTransaction?.id,
        userId: uid,
        title: title.trim(),
        amount: amount,
        type: type,
        categoryId: categoryId,
        date: date,
      );

      if (existingTransaction != null) {
        await _txrepo.updateTransaction(transaction);
      } else {
        await _txrepo.addTransaction(transaction);
      }
      return true;
    } catch (e) {
      rethrow; 
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _txsub?.cancel();
    _catSub?.cancel();
    super.dispose();
  }
}