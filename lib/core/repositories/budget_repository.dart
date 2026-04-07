import 'dart:async';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:rxdart/rxdart.dart';

class BudgetRepository {
  final FirestoreService _service;
  final _budgetsSubject = BehaviorSubject<List<Budget>>();
  StreamSubscription? _sub;

  BudgetRepository({FirestoreService? service})
   : _service = service ?? FirestoreService.instance;

  Stream<List<Budget>> get budgetsStream => _budgetsSubject.stream;

  void fetchBudgets(String monthYear) {
    _sub?.cancel();
    _sub = _service.streamBudgets(monthYear: monthYear).listen(
      (data) => _budgetsSubject.add(data),
      onError: (e) => _budgetsSubject.addError(e),
    );
  }

  Future<void> updateBudget(String categoryId, double amount, String monthYear) async {
    await _service.setBudget(
      categoryId: categoryId,
      amount: amount,
      monthYear: monthYear,
    );
  }

  Future<void> refresh() async {
    _sub?.cancel();
    await _budgetsSubject.first.timeout(const Duration(seconds: 5));
  }

  void dispose() {
    _sub?.cancel();
    _budgetsSubject.close();
  }
}