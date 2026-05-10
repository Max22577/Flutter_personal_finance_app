import 'dart:async';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/savings_service.dart';
import 'package:rxdart/subjects.dart';
import '../../models/savings.dart';
import '../services/firestore_service.dart';

class SavingsRepository {
  final FirestoreService _firestore;
  final SavingsService _savingsService;
  final exchangeService = ExchangeRateService(FirestoreService.instance);
  final _savingsSubject = BehaviorSubject<List<SavingsGoal>>();
  StreamSubscription? _savingsSub;

  SavingsRepository({FirestoreService? firestore, SavingsService? savingsService})
   : _firestore = firestore ?? FirestoreService.instance,
    _savingsService = savingsService ?? SavingsService.instance {
    _init();
  }

  void _init() {
    _savingsSub = _firestore.streamSavingsGoals().listen(
      (goals) => _savingsSubject.add(goals),
      onError: (e) => _savingsSubject.addError(e),  
    );
  }

  Stream<List<SavingsGoal>> get goalsStream => _savingsSubject.stream;
    
  Future<void> addGoal(SavingsGoal goal) => _firestore.addSavingsGoal(goal);

  Future<void> updateGoal(SavingsGoal goal) => _firestore.updateSavingsGoal(goal);

  Future<void> deleteGoal(String id) => _firestore.deleteSavingsGoal(id);

  Future<bool> addToGoal({
    required String goalId,
    required double amount,
    required String currency,
    required String note,
    required String defaultNote,
  }) async {
    final baseAmount = exchangeService.toBase(amount, currency);
    await _savingsService.addToSavingsGoal(
      goalId: goalId,
      amount: amount,
      baseAmount: baseAmount,
      currency: currency,
      transactionNote: note.isNotEmpty ? note : defaultNote,
    );
    return true;

  }

  Future <void> refresh() async {
    _savingsSub?.cancel();
    _init();
    await _savingsSubject.first.timeout(const Duration(seconds: 5));
  }

  void dispose() {
    _savingsSub?.cancel();
    _savingsSubject.close();
  }

}