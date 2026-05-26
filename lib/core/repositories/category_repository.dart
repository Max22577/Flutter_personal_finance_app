import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/firestore/constants/firestore_path.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/category.dart';

class CategoryRepository {
  final IFirestoreService _service;
  final FirebaseAuth _auth;
  StreamSubscription<List<Category>>? _cacheSubscription;

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


  CategoryRepository({required IFirestoreService service, required FirebaseAuth auth}) 
    : _service = service, _auth = auth{
      _cacheSubscription = allCategoriesStream.listen((_) {});
    }

  void dispose() {
    _cacheSubscription?.cancel();
  } 
  

  Stream<List<Category>> get allCategoriesStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value(predefinedCategories);

      return _service.streamCollection<Category>(
        collectionPath: categoriesCollectionPath,
        builder: (map) => Category.fromMap(map),
        orderBy: [OrderByOption('name', descending: false)]
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
  
      return _service.streamCollection<Category>(
        collectionPath: categoriesCollectionPath,
        builder: (map) => Category.fromMap(map),
        orderBy: [OrderByOption('name', descending: false)]
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
 
  String get categoriesCollectionPath => FirestorePath.categories(_auth.currentUser?.uid ?? '');

  Future<void> addCategory(Category category) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");
    await _service.addDocument(collectionPath: categoriesCollectionPath, data: category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");
    await _service.updateDocument(collectionPath: categoriesCollectionPath, documentId: category.id, data: category.toMap());
  }
}