import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/monthly_data.dart';


class MonthlyDataRepository {
  final FirestoreService _service;
  final CategoryRepository _catRepo;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _appId = (kDebugMode && !kIsWeb) ? 'debug-app-id' : String.fromEnvironment('APP_ID');

  MonthlyDataRepository(this._catRepo, {FirestoreService? service})
      : _service = service ?? FirestoreService.instance;

  // Collection reference helper
  CollectionReference _txRef(String uid) => 
      FirebaseFirestore.instance.collection('artifacts/$_appId/users/$uid/transactions');

  Stream<Map<String, MonthlyData>> get comparisonStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value({'current': MonthlyData.empty(), 'previous': MonthlyData.empty()});

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final prevMonth = DateTime(now.year, now.month - 1);

      return Rx.combineLatest2(
        streamMonthlyData(currentMonth),
        streamMonthlyData(prevMonth),
        (current, previous) => {'current': current, 'previous': previous},
      ).startWith({});
    });
  }

  Future<MonthlyData> getMonthlyData(DateTime month) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final range = _getDateRange(month);
    
    // Use the Future-based fetch from the Firestore service
    final transactions = await _service.getTransactionsInDateRange(
      _txRef(uid), 
      range.start, 
      range.end,
    );

    // Use the same calculation logic used by the streams!
    return _calculateMonthlyData(transactions, month);
  }

  Future<List<MonthlyData>> getReviewData(DateTime currentMonth) async {
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    
    return await Future.wait([
      getMonthlyData(currentMonth),
      getMonthlyData(previousMonth),
    ]);
  }

  Stream<MonthlyData> streamMonthlyData(DateTime month) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(MonthlyData.empty());

    final range = _getDateRange(month);
    final query = _txRef(uid)
        .where('date', isGreaterThanOrEqualTo: range.start)
        .where('date', isLessThanOrEqualTo: range.end)
        .orderBy('date', descending: true);
    return _service.streamCollection<Transaction>(
      query: query,
      builder: (doc) => Transaction.fromFirestore(doc),
    ).map((txs) => _calculateMonthlyData(txs, month));
  }

  // Helper for date math
  _DateRange _getDateRange(DateTime month) => _DateRange(
        start: DateTime(month.year, month.month, 1),
        end: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
      );

  // Calculation Logic (Calculates totals and breakdowns)
  MonthlyData _calculateMonthlyData(List<Transaction> transactions, DateTime month) {
    double income = 0;
    double expenses = 0;
    final breakdown = <String, double>{};

    for (var tx in transactions) {
      if (tx.type == 'Income') {
        income += tx.baseAmount;
      } else {
        expenses += tx.baseAmount;
        final catName = _catRepo.getNameByIdSync(tx.categoryId);
        if (catName.isEmpty) continue;
        breakdown.update(catName, (v) => v + tx.baseAmount, ifAbsent: () => tx.baseAmount);
      }
    }

    return MonthlyData(
      month: month,
      income: income,
      expenses: expenses,
      transactionCount: transactions.length,
      categoryBreakdown: breakdown,
    );
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;
  _DateRange({required this.start, required this.end});
}