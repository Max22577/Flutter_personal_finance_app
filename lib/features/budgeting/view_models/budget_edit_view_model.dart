import 'package:flutter/material.dart';

class BudgetEditViewModel extends ChangeNotifier {
  final Future<void> Function(String, double, DateTime) onSave;
  final String categoryId;
  final DateTime selectedDate;

  BudgetEditViewModel({
    required this.onSave,
    required this.categoryId,
    required this.selectedDate,
  });

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> updateBudget(String amountRaw) async {
    final amount = double.tryParse(amountRaw);
    if (amount == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      await onSave(categoryId, amount, selectedDate);
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