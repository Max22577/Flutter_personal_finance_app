import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import '../../models/transaction.dart';

class SavingsService {
  final TransactionRepository _transactionRepo;
  final SavingsRepository _savingsRepo;
  final IFirestoreService _firestoreService;

  SavingsService({
    required TransactionRepository transactionRepo,
    required SavingsRepository savingsRepo,
    required IFirestoreService firestoreService,
  })  : _transactionRepo = transactionRepo,
        _savingsRepo = savingsRepo,
        _firestoreService = firestoreService;

  // Add money to specific savings goal
  Future<void> addToSavingsGoal({
    required String goalId,
    required double amount,
    required double baseAmount,
    required String currency,
    String? transactionNote,
  }) async {
    try {
      // savings transaction
      final transaction = Transaction(
        userId:  _savingsRepo.currentUid,
        title: transactionNote ?? 'Savings Contribution',
        amount: amount,
        baseAmount: baseAmount,
        currency: currency,
        type: 'Expense', 
        categoryId: 'cat_savings', 
        date: DateTime.now(),
      );
      
      await _transactionRepo.addTransaction(transaction);
      _firestoreService.updateDocumentById(
        collectionPath: _savingsRepo.goalsCollectionPath, 
        documentId: goalId,
        data:{
            'currentAmount': FieldValue.increment(amount),
            'currentBaseAmount': FieldValue.increment(baseAmount),
            'lastContributionAt': FieldValue.serverTimestamp(),
          });
      
      debugPrint('Added $amount to savings goal $goalId');
    } catch (e) {
      debugPrint('Error adding to savings: $e');
      rethrow;
    }
  }
  
  // Withdraw from savings goal (if needed)
  Future<void> withdrawFromSavingsGoal({
    required String goalId,
    required double amount,
    required String currency,
    String? reason,
  }) async {
    try {
      final transaction = Transaction(
        userId:  _savingsRepo.currentUid,
        title: reason ?? 'Savings Withdrawal',
        amount: amount,
        baseAmount: amount, 
        currency: currency,
        type: 'Income', 
        categoryId: 'cat_savings',
        date: DateTime.now(),
      );
      
      await _transactionRepo.addTransaction(transaction);
  
      await _firestoreService.updateDocumentById(
        collectionPath: _savingsRepo.goalsCollectionPath,
        documentId: goalId,
        data: {
          'currentAmount': FieldValue.increment(-amount),
          'lastWithdrawalAt': FieldValue.serverTimestamp(),
        }
      );
      
      debugPrint('Withdrew $amount from savings goal $goalId');
    } catch (e) {
      debugPrint('Error withdrawing from savings: $e');
      rethrow;
    }
  }
}