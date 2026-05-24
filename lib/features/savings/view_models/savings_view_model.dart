import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import '../../../models/savings.dart';

class SavingsViewModel extends ChangeNotifier {
  final SavingsRepository _repository;
  final ExchangeRateService _exchangeService;
  final CurrencyProvider _currencyProvider;

  SavingsViewModel(this._repository, this._exchangeService, this._currencyProvider);

  // THE MASTER STREAM: Maps the raw goals list into a UI-ready State
  Stream<SavingsState> get stateStream => _repository.goalsStream.map((goals) {
    final totalTarget = goals.fold(0.0, (sum, g) => sum + _exchangeService.fromBase(g.targetBaseAmount, _currencyProvider.currentCurrency));
    final totalSaved = goals.fold(0.0, (sum, g) => sum + _exchangeService.fromBase(g.currentBaseAmount, _currencyProvider.currentCurrency));

    return SavingsState(
      goals: goals,
      totalTargetBase: totalTarget,
      totalSavedBase: totalSaved,
      remainingBase: (totalTarget - totalSaved).clamp(0.0, double.infinity),
      overallProgress: totalTarget == 0 ? 0.0 : (totalSaved / totalTarget).clamp(0.0, 1.0),
    );
  });

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
  }

  Future<void> refresh() async {
    notifyListeners(); 
    await Future.delayed(const Duration(milliseconds: 800));
  }
}

// Data holder for the Savings Screen
class SavingsState {
  final List<SavingsGoal> goals;
  final double totalTargetBase;
  final double totalSavedBase;
  final double remainingBase;
  final double overallProgress;

  SavingsState({
    required this.goals,
    required this.totalTargetBase,
    required this.totalSavedBase,
    required this.remainingBase,
    required this.overallProgress,
  });
}