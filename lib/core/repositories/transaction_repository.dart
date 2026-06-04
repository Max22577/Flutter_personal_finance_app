import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/firestore/constants/firestore_path.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/transaction.dart';

class TransactionRepository {
  final IFirestoreService _service;
  final FirebaseAuth _auth;

  final _monthController = BehaviorSubject<DateTime>.seeded(DateTime.now());

  TransactionRepository({required IFirestoreService service, required FirebaseAuth auth})
      : _service = service,
        _auth = auth;


  // The Reactive Master Stream
  Stream<List<Transaction>> get transactionsStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value([]);
    
      return _service.streamCollection<Transaction>(
        collectionPath: transactionsCollectionPath,
        builder: (map) => Transaction.fromMap(map),
        orderBy: [OrderByOption('date', descending: true)],
      );
    });
  }

  Stream<List<Transaction>> getRecentTransactions(int limit) {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value([]);
      
      return _service.streamCollection<Transaction>(
        collectionPath: transactionsCollectionPath,
        builder: (map) => Transaction.fromMap(map),
        orderBy: [OrderByOption('date', descending: true)],
        limit: limit, 
      );
    });
  }

  void setMonth(DateTime date) => _monthController.add(date);

  String get currentUid => _auth.currentUser?.uid ?? '';
  String get transactionsCollectionPath => FirestorePath.transactions(currentUid);

  Future<void> addTransaction(Transaction tx) async {
    final uid = currentUid;
    if (uid.isEmpty) throw Exception("Unauthorized");
    await _service.addDocument(collectionPath: transactionsCollectionPath, data: tx.toFirestore());
  }

  Future<void> updateTransaction(Transaction tx) async {
    if (tx.id.isEmpty) throw Exception("ID Required");
    await _service.updateDocument(collectionPath: transactionsCollectionPath, documentId: tx.id, data: tx.toFirestore());
  }

  Future<void> deleteTransaction(String id) async {
    await _service.deleteDocument(collectionPath: transactionsCollectionPath, id: id);
  }
}
