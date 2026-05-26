import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/firestore/constants/firestore_path.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/savings.dart';

class SavingsRepository {
  final IFirestoreService _service;
  final TransactionRepository _txRepo;
  final ExchangeRateService _exchangeService;
  final FirebaseAuth _auth;

  SavingsRepository(
    this._txRepo, {
    required IFirestoreService service,
    required ExchangeRateService exchangeService,
    required FirebaseAuth auth,
  })  : _service = service,
        _exchangeService = exchangeService,
        _auth = auth;


  String get goalsCollectionPath => FirestorePath.savingsGoals(currentUid);
  String get currentUid => _auth.currentUser?.uid ?? '';

  // REACTIVE MASTER STREAM
  Stream<List<SavingsGoal>> get goalsStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value([]);

      return _service.streamCollection<SavingsGoal>(
        collectionPath: goalsCollectionPath,
        builder: (map) => SavingsGoal.fromMap(map), 
        orderBy: [
          OrderByOption('deadline', descending: false),
        ],
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

    final tx = Transaction(
      id: '',
      userId: uid,
      title: note.isNotEmpty ? note : 'Savings Contribution',
      amount: amount,
      baseAmount: baseAmount,
      currency: currency,
      type: 'Expense',
      categoryId: 'cat_savings',
      date: DateTime.now(),
    );

    await _txRepo.addTransaction(tx);

    await _service.updateDocument(
      collectionPath: goalsCollectionPath,
      documentId: goalId,      
      data: {
        'currentAmount': FieldValue.increment(amount),
        'currentBaseAmount': FieldValue.increment(baseAmount),
        'lastContributionAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // Standard CRUD
  Future<void> addGoal(SavingsGoal goal) => _service.addDocument(collectionPath: goalsCollectionPath, data: goal.toFirestore());
  Future<void> updateGoal(SavingsGoal goal) => _service.updateDocument(collectionPath: goalsCollectionPath, documentId: goal.id, data: goal.toFirestore());
  Future<void> deleteGoal(String id) => _service.deleteDocument(collectionPath: goalsCollectionPath, id: id);
}