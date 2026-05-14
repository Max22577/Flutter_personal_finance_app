import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/transaction.dart';

class TransactionRepository {
  final IFirestoreService _service;
  final FirebaseAuth _auth;
  final String _appId = (kDebugMode && !kIsWeb) ? 'debug-app-id' : String.fromEnvironment('APP_ID');

  final _monthController = BehaviorSubject<DateTime>.seeded(DateTime.now());

  TransactionRepository({required IFirestoreService service, required FirebaseAuth auth})
      : _service = service,
        _auth = auth;

  // The Reactive Master Stream
  Stream<List<Transaction>> get transactionsStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value([]);

      final query = _txRef(user.uid).orderBy('date', descending: true);
      
      return _service.streamCollection<Transaction>(
        query: query,
        builder: (doc) => Transaction.fromFirestore(doc),
      );
    });
  }

  Stream<List<Transaction>> get monthlyTransactionsStream {
    return Rx.combineLatest2(
      _auth.authStateChanges(),
      _monthController.stream,
      (user, date) => _TxParams(user?.uid, date),
    ).switchMap((params) {
      if (params.uid == null) return Stream.value([]);

      final start = DateTime(params.date.year, params.date.month, 1);
      final end = DateTime(params.date.year, params.date.month + 1, 0, 23, 59, 59);

      final query = _txRef(params.uid!)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true);

      return _service.streamCollection<Transaction>(
        query: query,
        builder: (doc) => Transaction.fromFirestore(doc),
      );
    });
  }

  void setMonth(DateTime date) => _monthController.add(date);

  // Path Helper
  CollectionReference _txRef(String uid) => 
      FirebaseFirestore.instance.collection('artifacts/$_appId/users/$uid/transactions');

  String get currentUid => _auth.currentUser?.uid ?? '';

  Future<void> addTransaction(Transaction tx) async {
    final uid = currentUid;
    if (uid.isEmpty) throw Exception("Unauthorized");
    await _service.addDocument(_txRef(uid), tx.toFirestore());
  }

  Future<void> updateTransaction(Transaction tx) async {
    if (tx.id == null) throw Exception("ID Required");
    await _service.updateDocument(_txRef(currentUid).doc(tx.id), tx.toFirestore());
  }

  Future<void> deleteTransaction(String id) async {
    await _service.deleteDocument(_txRef(currentUid), id);
  }
}

class _TxParams {
  final String? uid;
  final DateTime date;
  _TxParams(this.uid, this.date);
}