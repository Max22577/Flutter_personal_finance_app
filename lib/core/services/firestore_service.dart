import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';

class FirestoreService implements IFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // CRUD Operations 
  @override
  Stream<List<T>> streamCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> doc) builder,
    List<FieldFilter>? filters,
    List<OrderByOption>? orderBy,
    int? limit,
  }) {
    Query query = _firestore.collection(collectionPath);

    // Dynamically apply any filters passed by the repository
    if (filters != null) {
      for (final filter in filters) {
        switch (filter.operator) {
          case FilterOperator.isEqualTo:
            query = query.where(filter.field, isEqualTo: filter.value);
            break;
          case FilterOperator.isGreaterThanOrEqualTo:
            query = query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
            break;
          case FilterOperator.isLessThanOrEqualTo:
            query = query.where(filter.field, isLessThanOrEqualTo: filter.value);
            break;
        }
      }
    }

    // Dynamically apply sorting configuration
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    // Optionally apply pagination limits
    if (limit != null) {
      query = query.limit(limit);
    }

    // Stream and map snapshots to your model builders
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        // Ensure your models can inject document IDs smoothly if needed
        if (data.containsKey('id') == false) {
          data['id'] = doc.id;
        }
        return builder(data);
      }).toList();
    });
  }

  @override
  Future<void> addDocument({required String collectionPath, required Map<String, dynamic> data}) async {
    await _firestore.collection(collectionPath).add(data);
  }

  @override
  Future<void> updateDocument({required String collectionPath, required String documentId, required Map<String, dynamic> data}) async {
    await _firestore.collection(collectionPath).doc(documentId).update(data);
  }

  @override
  Future<void> deleteDocument({required String collectionPath, required String id}) async {
    await _firestore.collection(collectionPath).doc(id).delete();
  }

  @override
  Future<void> setDocument({
    required String collectionPath, 
    required String documentId, 
    required Map<String, dynamic> data,
    bool merge = true, // Merge true prevents accidentally erasing fields if you add fields later
  }) async {
    await _firestore
        .collection(collectionPath)
        .doc(documentId)
        .set(data, SetOptions(merge: merge));
  }

  @override
  Future<List<T>> getCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> doc) builder,
    List<FieldFilter>? filters,
    List<OrderByOption>? orderBy,
    int? limit,
  }) async {
    Query query = _firestore.collection(collectionPath);

    if (filters != null) {
      for (final filter in filters) {
        switch (filter.operator) {
          case FilterOperator.isEqualTo:
            query = query.where(filter.field, isEqualTo: filter.value);
            break;
          case FilterOperator.isGreaterThanOrEqualTo:
            query = query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
            break;
          case FilterOperator.isLessThanOrEqualTo:
            query = query.where(filter.field, isLessThanOrEqualTo: filter.value);
            break;
        }
      }
    }

    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    if (limit != null) query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      data['id'] = doc.id;
      return builder(data);
    }).toList();
  }
}
