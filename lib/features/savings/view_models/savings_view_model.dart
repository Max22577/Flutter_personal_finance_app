import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import '../../../models/savings.dart';


class SavingsViewModel extends ChangeNotifier {
  final SavingsRepository _repository;
  
  List<SavingsGoal> _goals = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _subscription;

  SavingsViewModel(this._repository) {
    _init();
  }

  // Getters
  List<SavingsGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed Stats
  double get totalTargetBase => _goals.fold(0.0, (sum, g) => sum + g.targetBaseAmount);
  double get totalSavedBase => _goals.fold(0.0, (sum, g) => sum + g.currentBaseAmount);

  // Remaining amount in Base Currency
  double get remainingBase => (totalTargetBase - totalSavedBase).clamp(0.0, double.infinity);

  // Overall Progress remains accurate regardless of exchange rates
  double get overallProgress => totalTargetBase == 0 
    ? 0 
    : (totalSavedBase / totalTargetBase).clamp(0.0, 1.0);

  void _init() {
    _subscription = _repository.goalsStream.listen(
      (goals) {
        _goals = goals;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    await _repository.refresh();
    _isLoading = true;
    notifyListeners();
  }

  Future<void> retry() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await refresh();
  }


  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}