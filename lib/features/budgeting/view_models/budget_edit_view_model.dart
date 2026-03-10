import 'package:flutter/material.dart';

class BudgetEditViewModel extends ChangeNotifier {
  final Future<void> Function(String, double, String) onSave;
  final String categoryId;
  final String monthYear;

  BudgetEditViewModel({
    required this.onSave,
    required this.categoryId,
    required this.monthYear,
  });

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> updateBudget(String amountRaw) async {
    final amount = double.tryParse(amountRaw);
    if (amount == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      await onSave(categoryId, amount, monthYear);
      return true;
    } catch (e) {
      debugPrint('Error saving budget: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}