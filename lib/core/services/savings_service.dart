import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import '../../models/transaction.dart';

class SavingsService {
  static final SavingsService _instance = SavingsService._internal();
  factory SavingsService() => _instance;
  SavingsService._internal();
  
  final FirestoreService _firestore = FirestoreService.instance;
  
  // Add money to specific savings goal
  Future<void> addToSavingsGoal({
    required String goalId,
    required double amount,
    String? transactionNote,
  }) async {
    try {
      // 1. Create a dedicated savings transaction
      final transaction = Transaction(
        userId:  _firestore.currentUid,
        title: transactionNote ?? 'Savings Contribution',
        amount: amount,
        type: 'Expense', 
        categoryId: 'cat_savings', 
        date: DateTime.now(),
      );
      
      await _firestore.addTransaction(transaction);
      final savingsGoalRef = await _firestore.savingsGoalsCollectionRef();
      await savingsGoalRef
          .doc(goalId)
          .update({
            'currentAmount': FieldValue.increment(amount),
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
    String? reason,
  }) async {
    try {
      final transaction = Transaction(
        userId:  _firestore.currentUid,
        title: reason ?? 'Savings Withdrawal',
        amount: amount,
        type: 'Income', 
        categoryId: 'cat_savings',
        date: DateTime.now(),
      );
      
      await _firestore.addTransaction(transaction);
      final savingsGoalRef = await _firestore.savingsGoalsCollectionRef();
  
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