import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/category.dart';

class CategoryViewModel extends ChangeNotifier {
  final _firestore = FirestoreService.instance;
  final CategoryRepository _catRepo;
  bool _isBusy = false;

  CategoryViewModel(this._catRepo);
    
  bool get isBusy => _isBusy;
  List<Category> get predefinedCategories => _firestore.predefinedCategories;

  // Stream for the UI to listen to
  Stream<List<Category>> get customCategoriesStream => _catRepo.customCategoriesStream;

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    _setBusy(true);
    try {
      await _firestore.addCategory(name.trim());
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateCategory(String id, String newName) async {
    _setBusy(true);
    try {
      await _firestore.updateCategoryName(id, newName.trim());
    } finally {
      _setBusy(false);
    }
  }
}