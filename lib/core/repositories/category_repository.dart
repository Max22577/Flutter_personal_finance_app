import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:rxdart/rxdart.dart';
import '../../models/category.dart';
import '../services/firestore_service.dart';

class CategoryRepository {
  final FirestoreService _service;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _appId = (kDebugMode && !kIsWeb) ? 'debug-app-id' : String.fromEnvironment('APP_ID');
  List<Category> _cache = [
    Category(id: 'cat_food', name: 'Food'),
    Category(id: 'cat_trans', name: 'Transportation'),
    Category(id: 'cat_salary', name: 'Salary'),
    Category(id: 'cat_rent', name: 'Rent'),
    Category(id: 'cat_savings', name: 'Savings'),
  ];

  final List<Category> predefinedCategories = [
    Category(id: 'cat_food', name: 'Food'),
    Category(id: 'cat_trans', name: 'Transportation'),
    Category(id: 'cat_salary', name: 'Salary'),
    Category(id: 'cat_rent', name: 'Rent'),
    Category(id: 'cat_savings', name: 'Savings'),
  ];


  CategoryRepository({FirestoreService? service}) 
    : _service = service ?? FirestoreService.instance; 
  

  Stream<List<Category>> get allCategoriesStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value(predefinedCategories);

      final query = _categoriesRef(user.uid).orderBy('name', descending: false);
      return _service.streamCollection<Category>(
        query: query,
        builder: (doc) => Category.fromFirestore(doc),
      ).map((customs) {
        final fullList = [...predefinedCategories, ...customs];
        
        _cache = fullList; 
        
        return fullList;
      });
    });
  }

  Stream<List<Category>> get customCategoriesOnlyStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value([]); 
      
      final ref = _categoriesRef(user.uid);
      final query = ref.orderBy('name', descending: false);
      return _service.streamCollection<Category>(
        query: query,
        builder: (doc) => Category.fromFirestore(doc),
      );
    });
  }

  String getNameByIdSync(String id) {
    try {
      return _cache.firstWhere((cat) => cat.id == id).name;
    } catch (_) {
      return 'Unknown Category';
    }
  }

  List<Category> get categories => _cache;
  // Helper to build the path
  CollectionReference _categoriesRef(String uid) => 
      FirebaseFirestore.instance.collection('artifacts/$_appId/users/$uid/transaction_categories');

  Future<void> addCategory(Category category) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");
    await _service.addDocument(_categoriesRef(uid), category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");
    await _service.updateDocument(_categoriesRef(uid).doc(category.id), category.toMap());
  }
}