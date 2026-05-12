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
    required String currency,
    required String note,
  }) async {
    if (amount <= 0) return false;

    _setProcessing(true);

    try {
      // Call the consolidated logic in the Repository
      await _repository.contributeToGoal(
        goalId: goalId,
        amount: amount,
        currency: currency,
        note: note,
      );
      return true;
    } catch (e) {
      debugPrint("Add to Savings Error: $e");
      return false;
    } finally {
      _setProcessing(false);
    }
  }

  void _setProcessing(bool val) {
    _isProcessing = val;
    notifyListeners();
  }
}