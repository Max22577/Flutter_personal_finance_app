import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import '../../models/transaction.dart';

class SavingsService {
  static final SavingsService _instance = SavingsService._internal();
  factory SavingsService() => _instance;
  SavingsService._internal();
  static SavingsService get instance => _instance;
  final TransactionRepository _transactionRepo = TransactionRepository();
  final SavingsRepository _savingsRepo = SavingsRepository(TransactionRepository());
  
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
      final savingsGoalRef = _savingsRepo.goalsCollectionRef;
      await savingsGoalRef
          .doc(goalId)
          .update({
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
        baseAmount: amount, // Assuming base amount is the same as the withdrawal amount
        currency: currency,
        type: 'Income', 
        categoryId: 'cat_savings',
        date: DateTime.now(),
      );
      
      await _transactionRepo.addTransaction(transaction);
      final savingsGoalRef = _savingsRepo.goalsCollectionRef;
  
      await savingsGoalRef
          .doc(goalId)
          .update({
            'currentAmount': FieldValue.increment(-amount),
            'lastWithdrawalAt': FieldValue.serverTimestamp(),
          });
      
      debugPrint('Withdrew $amount from savings goal $goalId');
    } catch (e) {
      debugPrint('Error withdrawing from savings: $e');
      rethrow;
    }
  }
}