import 'dart:async';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import '../../../models/savings.dart';

class SavingsViewModel {
  final SavingsRepository _repository;


  SavingsViewModel(this._repository);

  // THE MASTER STREAM: Maps the raw goals list into a UI-ready State
  Stream<SavingsState> get stateStream {
    return _repository.goalsStream.map((goals) {
      final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
      final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);

      return SavingsState(
        goals: goals,
        totalTarget: totalTarget,
        totalSaved: totalSaved,
        remaining: (totalTarget - totalSaved).clamp(0.0, double.infinity),
        overallProgress: totalTarget == 0 ? 0.0 : (totalSaved / totalTarget).clamp(0.0, 1.0),
      );
    });
  }

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
  }

}

// Data holder for the Savings Screen
class SavingsState {
  final List<SavingsGoal> goals;
  final double totalTarget;
  final double totalSaved;
  final double remaining;
  final double overallProgress;

  SavingsState({
    required this.goals,
    required this.totalTarget,
    required this.totalSaved,
    required this.remaining,
    required this.overallProgress,
  });
}