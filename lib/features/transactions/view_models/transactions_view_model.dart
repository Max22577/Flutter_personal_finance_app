import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/category.dart';


class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;
  final ExchangeRateService _exchangeService;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  TransactionViewModel(this._txRepo, this._catRepo) 
      : _exchangeService = ExchangeRateService();

  Stream<List<Transaction>> get transactions => _txRepo.transactionsStream;
  Stream<List<Category>> get categoriesStream => _catRepo.allCategoriesStream;
  List<Category> get categories => _catRepo.categories; 

  Map<DateTime, List<Transaction>> groupTransactions(List<Transaction> list) {
    final Map<DateTime, List<Transaction>> groups = {};
    for (var tx in list) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groups.putIfAbsent(date, () => []).add(tx);
    }
    return groups;
  }

  Future<bool> saveTransaction({
    required String title,
    required double amount,
    required String currency,
    required String type,
    required String categoryId,
    required DateTime date,
    Transaction? existingTransaction,
  }) async {
    _setSaving(true);
    try {
      final transaction = Transaction(
        id: existingTransaction?.id,
        userId: _txRepo.currentUid,
        title: title.trim(),
        amount: amount,
        currency: currency,
        baseAmount: _exchangeService.toBase(amount, currency),
        type: type,
        categoryId: categoryId,
        date: date,
      );

      if (existingTransaction != null) {
        await _txRepo.updateTransaction(transaction);
      } else {
        await _txRepo.addTransaction(transaction);
      }
      return true;
    } catch (e) {
      debugPrint("Save Error: $e");
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _txRepo.deleteTransaction(id);
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  void _setSaving(bool val) {
    _isSaving = val;
    notifyListeners();
  }
}