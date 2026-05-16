import 'package:personal_fin/core/network/query_options.dart';

abstract class IFirestoreService {
  Stream<List<T>> streamCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> doc) builder,
    List<FieldFilter>? filters,
    List<OrderByOption>? orderBy,
    int? limit,
  });

  Future<void> addDocument({required String collectionPath, required Map<String, dynamic> data});
  Future<void> updateDocument({required String collectionPath, required String documentId, required Map<String, dynamic> data});
  Future<void> deleteDocument({required String collectionPath, required String id});
  

  Future<List<T>> getCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> doc) builder,
    List<FieldFilter>? filters,
    List<OrderByOption>? orderBy,
    int? limit,
  });

}