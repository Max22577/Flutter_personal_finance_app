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
  StreamSubscription? _authAndDataSubscription;

  // Single Source of Truth for the cache. Starts with predefined categories.
  final BehaviorSubject<List<Category>> _categoriesSubject;

  static final List<Category> _predefinedCategories = [
    Category(id: 'cat_food', name: 'Food'),
    Category(id: 'cat_trans', name: 'Transportation'),
    Category(id: 'cat_salary', name: 'Salary'),
    Category(id: 'cat_rent', name: 'Rent'),
    Category(id: 'cat_savings', name: 'Savings'),
  ];

  CategoryRepository({required IFirestoreService service, required FirebaseAuth auth}) 
    : _service = service, 
      _auth = auth,
      _categoriesSubject = BehaviorSubject<List<Category>>.seeded(_predefinedCategories) {
      _initSyncPipeline();
  }

  /// Sets up a single pipeline that manages user changes and data updates cleanly
  void _initSyncPipeline() {
    _authAndDataSubscription = _auth.authStateChanges().switchMap((user) {
      if (user == null) {
        // If logged out, immediately reset cache back to predefined defaults
        return Stream.value(_predefinedCategories);
      }

      // Single active query listener to Firestore
      return _service.streamCollection<Category>(
        collectionPath: FirestorePath.categories(user.uid),
        builder: (map) => Category.fromMap(map),
        orderBy: [OrderByOption('name', descending: false)]
      ).map((customs) {
        return [..._predefinedCategories, ...customs];
      });
    }).listen((fullList) {
      _categoriesSubject.add(fullList);
    });
  }

  void dispose() {
    _authAndDataSubscription?.cancel();
    _categoriesSubject.close();
  } 


  /// Exposes the combined list of predefined and custom items
  Stream<List<Category>> get allCategoriesStream => _categoriesSubject.stream;
  List<Category> get predefinedCategories => _predefinedCategories;


  Stream<List<Category>> get customCategoriesOnlyStream {
    return _categoriesSubject.stream.map((list) {
      return list.where((c) => !c.id.startsWith('cat_')).toList();
    });
  }

  Category? getCategoryByIdSync(String id) {
    try {
      return _categoriesSubject.value.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Category> get categories => _categoriesSubject.value;
  
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