import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../models/category.dart';
import '../services/firestore_service.dart';

class CategoryRepository {
  final FirestoreService _service;
  final _categorySubject = BehaviorSubject<List<Category>>(); //pre-defined and user defined categories
  final _userCategorySubject = BehaviorSubject<List<Category>>(); //user defined categories
  StreamSubscription? _catSub;
  StreamSubscription? _userCatSub;


  CategoryRepository({FirestoreService? service}) 
    : _service = service ?? FirestoreService.instance {
      _init();
  }

  void _init() {
    // Listen once to the Firestore stream
    _catSub = _service.streamCategories().listen(
      (data) => _categorySubject.add(data),
      onError: (e) => _categorySubject.addError(e),
    );

    _userCatSub = _service.streamCustomCategories().listen(
      (data) => _userCategorySubject.add(data),
      onError: (e) => _userCategorySubject.addError(e),
    );
  }

  // The stream shared by the whole app
  Stream<List<Category>> get categoriesStream => _categorySubject.stream;
  Stream<List<Category>> get customCategoriesStream => _userCategorySubject.stream;
  List<Category> get predefinedCategories => _service.predefinedCategories;

  Future<void> addCategory(String name) async {
    await _service.addCategory(name);
  }

  Future<void> updateCategory(String id, String newName) async {
    await _service.updateCategoryName(id, newName);
  }

  // Sync refresh if needed
  Future<void> refresh() async {
    _catSub?.cancel();
    _userCatSub?.cancel();
    _init();
    await _categorySubject.first.timeout(const Duration(seconds: 5));
    await _userCategorySubject.first.timeout(const Duration(seconds: 5));
  }

  void dispose() {
    _catSub?.cancel();
    _userCatSub?.cancel();
    _categorySubject.close();
  }
}