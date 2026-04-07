import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
class AddToSavingsViewModel extends ChangeNotifier {
  final SavingsRepository _repository;

  AddToSavingsViewModel(this._repository);
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  Future<bool> addToGoal({
    required String goalId,
    required double amount,
    required String note,
    required String defaultNote,
  }) async {
    if (amount <= 0) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      await _repository.addToGoal(
        goalId: goalId,
        amount: amount,
        note: note,
        defaultNote: defaultNote,
      );
      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
}