import 'dart:async';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';

class MonthlyTransactionRepository {
  final FirestoreService _service;
  final _monthlySub = BehaviorSubject<List<Transaction>>();
  StreamSubscription? _sub;

  Stream<List<Transaction>> get stream => _monthlySub.stream;

  MonthlyTransactionRepository({FirestoreService? service})
   : _service = service ?? FirestoreService.instance;

  void fetchForMonth(String monthYear) {
    _sub?.cancel();
    _sub = _service.streamMonthlyTransactions(monthYear: monthYear).listen(
      (data) => _monthlySub.add(data),
    );
  }

  Future<void> refresh() async {
    _sub?.cancel();  
    await _monthlySub.first.timeout(const Duration(seconds: 5));
  }

  void dispose() {
    _sub?.cancel();
    _monthlySub.close();
  }
}