import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:personal_fin/models/transaction.dart';

class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  // CRUD Operations 
  Stream<List<T>> streamCollection<T>({
    required Query query,
    required T Function(DocumentSnapshot doc) builder,
  }) {
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => builder(doc)).toList());
  }

  Future<void> addDocument(CollectionReference ref, Map<String, dynamic> data) async {
    await ref.add(data);
  }

  Future<void> updateDocument(DocumentReference ref, Map<String, dynamic> data) async {
    await ref.update(data);
  }

  Future<void> deleteDocument(CollectionReference ref, String id) async {
  await ref.doc(id).delete(); 
}

  Future<List<Transaction>> getTransactionsInDateRange(
    CollectionReference ref, 
    DateTime start, 
    DateTime end,
  ) async {
    final query = await ref
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true)
        .get();
    return query.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
  }

  Future<void> saveBudget(DocumentReference docRef, Map<String, dynamic> data) async {
    // Set with merge handles both creation and updates
    await docRef.set(data, SetOptions(merge: true));
  }

}
