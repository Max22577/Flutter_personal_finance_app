import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:personal_fin/models/transaction.dart';

abstract class IFirestoreService {
  Stream<List<T>> streamCollection<T>({
    required Query query,
    required T Function(DocumentSnapshot doc) builder,
  });

  Future<void> addDocument(CollectionReference ref, Map<String, dynamic> data);
  Future<void> updateDocument(DocumentReference ref, Map<String, dynamic> data);
  Future<void> deleteDocument(CollectionReference ref, String id);
  Future<void> saveBudget(DocumentReference docRef, Map<String, dynamic> data);

  Future<List<Transaction>> getTransactionsInDateRange(
    CollectionReference ref, 
    DateTime start, 
    DateTime end,
  );

  Future<void> updateDocumentById({
    required String collectionPath, 
    required String documentId, 
    required Map<String, dynamic> data,
  });
}