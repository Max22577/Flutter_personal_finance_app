import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/firestore/constants/firestore_path.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/monthly_data.dart';

class MonthlyDataRepository {
  final IFirestoreService _firestoreService;
  final FirebaseAuth _auth;
  final ExchangeRateService _exchangeService;

  MonthlyDataRepository({
    required CategoryRepository catRepo, 
    required ExchangeRateService exchangeService, 
    required IFirestoreService service, 
    required FirebaseAuth auth
  }) :
       _exchangeService = exchangeService,
       _firestoreService = service,
       _auth = auth;
      
  String get currentUid => _auth.currentUser?.uid ?? '';
  String get transactionsCollectionPath => FirestorePath.transactions(currentUid);
  ExchangeRateService get exchangeService => _exchangeService;
  

  // Real-time stream for a single targeted month
  Stream<MonthlyData> streamMonthlyData(DateTime month, String currencyCode) {
    if (currentUid.isEmpty) return Stream.value(MonthlyData.empty(month));

    final range = _getDateRange(month);

    return _firestoreService.streamCollection<Transaction>(
      collectionPath: transactionsCollectionPath,
      builder: (map) => Transaction.fromMap(map),
      filters: [
        FieldFilter('date', FilterOperator.isGreaterThanOrEqualTo, range.start),
        FieldFilter('date', FilterOperator.isLessThanOrEqualTo, range.end),
      ],
      orderBy: [OrderByOption('date', descending: true)],
    ).map((txs) => _calculateMonthlyData(txs, month, currencyCode));
  }

  // Reactive historical review data stream (Combines current and previous month reactively!)
  Stream<List<MonthlyData>> streamReviewData(DateTime currentMonth, String currencyCode) {
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    
    return Rx.combineLatest2(
      streamMonthlyData(currentMonth, currencyCode),
      streamMonthlyData(previousMonth, currencyCode),
      (current, previous) => [current, previous],
    );
  }

  _DateRange _getDateRange(DateTime month) => _DateRange(
        start: DateTime(month.year, month.month, 1),
        end: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
      );

  // One central calculator handles mapping raw transactions to domain data
  MonthlyData _calculateMonthlyData(List<Transaction> transactions, DateTime month, String currencyCode) {
    double income = 0;
    double expenses = 0;
    final breakdown = <String, double>{};

    for (var tx in transactions) {
      final amountInTarget = _exchangeService.fromBase(tx.baseAmount, currencyCode);
      if (tx.type == 'Income') {
        income += amountInTarget;
      } else {
        expenses += amountInTarget;
        if (tx.categoryId.isNotEmpty) {
          breakdown.update(
            tx.categoryId, 
            (v) => v + amountInTarget, 
            ifAbsent: () => amountInTarget,
          );
        }
      }
    }

    return MonthlyData(
      month: month,
      income: income,
      expenses: expenses,
      transactionCount: transactions.length,
      categoryBreakdown: breakdown,
      rawTransactions: transactions, 
    );
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;
  _DateRange({required this.start, required this.end});
}