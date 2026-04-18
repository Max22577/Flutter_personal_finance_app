import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/models/category.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _catRepo;
  bool _isBusy = false;
  String? _errorMessage;

  Future<void> Function()? _lastAction;

  CategoryViewModel(this._catRepo);
    
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  List<Category> get predefinedCategories => _catRepo.predefinedCategories;

  // Stream for the UI to listen to
  Stream<List<Category>> get customCategoriesStream => _catRepo.customCategoriesStream;

  void _setBusy(bool value) {
    _isBusy = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  Future<void> retryLastAction() async {
    if (_lastAction != null) {
      await _lastAction!();
    }
  }

  Future<void> refreshCategories() async {
    _lastAction = () => refreshCategories(); 
    _setBusy(true);
    try {
      await _catRepo.refresh();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Unable to sync categories. Check your connection.";
    } finally {
      _setBusy(false);
    }
  }

  Future<void> addCategory(String name) async {
    _lastAction = () => addCategory(name);
    _setBusy(true);
    try {
      await _catRepo.addCategory(name.trim());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to add category. Please try again.";
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateCategory(String id, String newName) async {
    _lastAction = () => updateCategory(id, newName);
    _setBusy(true);
    try {
      await _catRepo.updateCategory(id, newName.trim());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to add category. Please try again.";
    } finally {
      _setBusy(false);
    }
  }
}