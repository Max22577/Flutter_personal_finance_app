import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/savings.dart';
import '../services/firestore_service.dart';

class SavingsRepository {
  final FirestoreService _service;
  final TransactionRepository _txRepo;
  final ExchangeRateService _exchangeService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
   final String _appId = (kDebugMode && !kIsWeb) ? 'debug-app-id' : String.fromEnvironment('APP_ID');

  SavingsRepository(this._txRepo, {FirestoreService? service})
      : _service = service ?? FirestoreService.instance,
        _exchangeService = ExchangeRateService();

  CollectionReference _goalsRef(String uid) =>
      FirebaseFirestore.instance.collection('artifacts/$_appId/users/$uid/savings_goals');

  CollectionReference get goalsCollectionRef => _goalsRef(currentUid);
  String get currentUid => _auth.currentUser?.uid ?? '';

  // REACTIVE MASTER STREAM
  Stream<List<SavingsGoal>> get goalsStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value([]);
      final query = _goalsRef(user.uid).orderBy('deadline', descending: false);
      return _service.streamCollection<SavingsGoal>(
        query: query,
        builder: (doc) => SavingsGoal.fromFirestore(doc),
      );
    });
  }

  // ATOMIC ACTION: Add a transaction AND update the goal progress
  Future<void> contributeToGoal({
    required String goalId,
    required double amount,
    required String currency,
    required String note,
  }) async {
    final uid = currentUid;
    final baseAmount = _exchangeService.toBase(amount, currency);

    // 1. Create the Transaction
    final tx = Transaction(
      userId: uid,
      title: note.isNotEmpty ? note : 'Savings Contribution',
      amount: amount,
      baseAmount: baseAmount,
      currency: currency,
      type: 'Expense',
      categoryId: 'cat_savings',
      date: DateTime.now(),
    );

    // 2. Add Transaction via TransactionRepo
    await _txRepo.addTransaction(tx);

    // 3. Update Goal Progress
    await _service.updateDocument(
      _goalsRef(uid).doc(goalId),
      {
        'currentAmount': FieldValue.increment(amount),
        'currentBaseAmount': FieldValue.increment(baseAmount),
        'lastContributionAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // Standard CRUD
  Future<void> addGoal(SavingsGoal goal) => _service.addDocument(_goalsRef(currentUid), goal.toFirestore());
  Future<void> updateGoal(SavingsGoal goal) => _service.updateDocument(_goalsRef(currentUid).doc(goal.id), goal.toFirestore());
  Future<void> deleteGoal(String id) => _service.deleteDocument(_goalsRef(currentUid), id);
}