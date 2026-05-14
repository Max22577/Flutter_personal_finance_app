import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';

class FirestoreService implements IFirestoreService {
  // CRUD Operations 
  @override
  Stream<List<T>> streamCollection<T>({
    required Query query,
    required T Function(DocumentSnapshot doc) builder,
  }) {
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => builder(doc)).toList());
  }

  @override
  Future<void> addDocument(CollectionReference ref, Map<String, dynamic> data) async {
    await ref.add(data);
  }

  @override
  Future<void> updateDocument(DocumentReference ref, Map<String, dynamic> data) async {
    await ref.update(data);
  }

  @override
  Future<void> deleteDocument(CollectionReference ref, String id) async {
  await ref.doc(id).delete(); 
}

  @override
  Future<List<Transaction>> getTransactionsInDateRange(
    CollectionReference ref, 
    DateTime start, 
    DateTime end,
  ) async {
    final querySnapshot = await ref
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true)
        .get();
    
    return querySnapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
  }

  @override
  Future<void> saveBudget(DocumentReference docRef, Map<String, dynamic> data) async {
    // Set with merge handles both creation and updates
    await docRef.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateDocumentById({
    required String collectionPath, 
    required String documentId, 
    required Map<String, dynamic> data,
  }) async {

    await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(documentId)
        .update(data);
  }

}
