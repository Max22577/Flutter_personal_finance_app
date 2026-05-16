import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/constants/firestore_path.dart';
import 'package:personal_fin/core/network/query_options.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/monthly_data.dart';

class MonthlyDataRepository {
  final IFirestoreService _firestoreService;
  final CategoryRepository _catRepo;
  final FirebaseAuth _auth;

  MonthlyDataRepository(this._catRepo, {required IFirestoreService service, required FirebaseAuth auth})
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

    return _firestoreService.streamCollection<Transaction>(
      collectionPath: transactionsCollectionPath,
      builder: (map) => Transaction.fromMap(map),
      filters: [
        FieldFilter('date', FilterOperator.isGreaterThanOrEqualTo, range.start),
        FieldFilter('date', FilterOperator.isLessThanOrEqualTo, range.end),
      ],
      orderBy: [OrderByOption('date', descending: true)],
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