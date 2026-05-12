import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/models/category.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repo;
  bool _isBusy = false;
  String? _errorMessage;

  CategoryViewModel(this._repo);

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  Stream<List<Category>> get categoriesStream => _repo.allCategoriesStream;
  Stream<List<Category>> get customCategoriesOnly => _repo.customCategoriesOnlyStream;
  List<Category> get predefinedCategories => _repo.predefinedCategories;

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  Future<void> saveCategory({
    String? id,
    required String name,
    required int iconCode,
    required int colorValue,
  }) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      final category = Category(
        id: id ?? '',
        name: name.trim(),
        iconCode: iconCode,
        colorValue: colorValue,
        isCustom: true,
      );

      if (id == null) {
        await _repo.addCategory(category);
      } else {
        await _repo.updateCategory(category);
      }
    } catch (e) {
      _errorMessage = "Failed to save category. Please try again.";
    } finally {
      _setBusy(false);
    }
  }
}