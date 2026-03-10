import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/models/savings.dart';

class SetGoalViewModel extends ChangeNotifier {
  final SavingsRepository _repository;
  final SavingsGoal? existingGoal;

  SetGoalViewModel(this._repository, {this.existingGoal}) {
    if (existingGoal != null) {
      name = existingGoal!.name;
      targetAmount = existingGoal!.targetAmount;
      deadline = existingGoal!.deadline;
    } else {
      deadline = DateTime.now().add(const Duration(days: 30));
    }
  }

  // State Variables
  String name = '';
  double targetAmount = 0.0;
  late DateTime deadline;
  bool isSaving = false;

  bool get isEditing => existingGoal != null;

  void updateName(String val) {
    name = val;
    notifyListeners();
  }

  void updateAmount(String val) {
    targetAmount = double.tryParse(val) ?? 0.0;
    notifyListeners();
  }

  void updateDeadline(DateTime date) {
    deadline = date;
    notifyListeners();
  }

  Future<bool> saveGoal({required String name, required double target}) async {
    isSaving = true;
    notifyListeners();

    try {
      final goal = SavingsGoal(
        id: existingGoal?.id,
        name: name,
        targetAmount: target,
        currentAmount: existingGoal?.currentAmount ?? 0.0,
        deadline: deadline,
      );

      if (isEditing) {
        await _repository.updateGoal(goal);
      } else {
        await _repository.addGoal(goal);
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGoal() async {
    if (existingGoal?.id == null) return false;
    try {
      await _repository.deleteGoal(existingGoal!.id!);
      return true;
    } catch (e) {
      return false;
    }
  }
}