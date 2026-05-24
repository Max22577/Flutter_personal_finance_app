import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/constants/firestore_path.dart';
import 'package:personal_fin/core/network/query_options.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/monthly_data.dart';

class MonthlyDataRepository {
  final IFirestoreService _firestoreService;
  final CategoryRepository _catRepo;
  final FirebaseAuth _auth;
  final ExchangeRateService _exchangeService;
  final CurrencyProvider _currencyProvider;

  MonthlyDataRepository(this._catRepo, this._exchangeService, this._currencyProvider, {required IFirestoreService service, required FirebaseAuth auth})
      : _firestoreService = service,
        _auth = auth;
    
  String get currentUid => _auth.currentUser?.uid ?? '';
  String get transactionsCollectionPath => FirestorePath.transactions(currentUid);

  Stream<Map<String, MonthlyData>> get comparisonStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value({'current': MonthlyData.empty(), 'previous': MonthlyData.empty()});

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final prevMonth = DateTime(now.year, now.month - 1);
      final currencyCode = _currencyProvider.currentCurrency;

      return Rx.combineLatest2(
        streamMonthlyData(currentMonth, currencyCode),
        streamMonthlyData(prevMonth, currencyCode),
        (current, previous) => {'current': current, 'previous': previous},
      ).startWith({});
    });
  }

  Future<MonthlyData> getMonthlyData(DateTime month, String currencyCode) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final range = _getDateRange(month);
    
    // Use the Future-based fetch from the Firestore service
    final transactions = await _firestoreService.getCollection<Transaction>(
      collectionPath: transactionsCollectionPath,
      builder: (map) => Transaction.fromMap(map),
      filters: [
        FieldFilter('date', FilterOperator.isGreaterThanOrEqualTo, range.start),
        FieldFilter('date', FilterOperator.isLessThanOrEqualTo, range.end),
      ],
      orderBy: [
        OrderByOption('date', descending: true),
      ],
    );

    // Use the same calculation logic used by the streams!
    return _calculateMonthlyData(transactions, month, currencyCode);
  }

  Future<List<MonthlyData>> getReviewData(DateTime currentMonth, String currencyCode) async {
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    
    return await Future.wait([
      getMonthlyData(currentMonth, currencyCode),
      getMonthlyData(previousMonth, currencyCode),
    ]);
  }

  Stream<MonthlyData> streamMonthlyData(DateTime month, String currencyCode) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(MonthlyData.empty());

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

  // Helper for date math
  _DateRange _getDateRange(DateTime month) => _DateRange(
        start: DateTime(month.year, month.month, 1),
        end: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
      );

  // Calculation Logic (Calculates totals and breakdowns)
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
        final catName = _catRepo.getNameByIdSync(tx.categoryId);
        if (catName.isEmpty) continue;
        breakdown.update(catName, (v) => v + amountInTarget, ifAbsent: () => amountInTarget);
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