import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:rxdart/rxdart.dart';


class DailyChartPoint {
  final int day;
  final double income;
  final double expenses;
  const DailyChartPoint({required this.day, this.income = 0.0, this.expenses = 0.0});
}

class MonthlyReviewViewModel extends ChangeNotifier {
  final MonthlyDataRepository _repo;
  final CurrencyProvider _currencyProvider;

  final _monthController = BehaviorSubject<DateTime>();
  
  MonthlyReviewViewModel(this._repo, this._currencyProvider, DateTime initialMonth) {
    _selectedMonth = initialMonth;
    _monthController.add(initialMonth);
  }

  late DateTime _selectedMonth;
  DateTime get selectedMonth => _selectedMonth;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MonthlyData? _currentMonthData;
  MonthlyData? get currentMonthData => _currentMonthData;

  MonthlyData? _previousMonthData;
  MonthlyData? get previousMonthData => _previousMonthData;

  void changeMonth(DateTime newMonth) {
    _selectedMonth = newMonth;
    _monthController.add(newMonth);
    notifyListeners();
  }

  // Stream combining current currency and selected month to fetch historical daily trend series
  Stream<List<DailyChartPoint>> get dailyTrendStream {
    return Rx.combineLatest2(
      _currencyProvider.currencyStream,
      _monthController.stream,
      (String code, DateTime month) => _fetchAndAggregateDailyPoints(month, code),
    ).switchMap((future) => Stream.fromFuture(future));
  }

  Stream<List<MonthlyData>> getReviewDataStream(DateTime month) {
    return _monthController.stream.switchMap((month) {
      return _currencyProvider.currencyStream.switchMap((currencyCode) {
        return Stream.fromFuture(_repo.getReviewData(month, currencyCode));
      });
    });
  }

  // Business Logic: Calculations moved out of UI
  double get savingsRate {
    if (_currentMonthData == null || _currentMonthData!.income <= 0) return 0.0;
    return (_currentMonthData!.net / _currentMonthData!.income).clamp(0.0, 1.0);
  }

  List<MapEntry<String, double>> get topSpendingCategories {
    if (_currentMonthData == null) return [];
    final allEntries = _currentMonthData!.categoryBreakdown.entries
        .toList()
        .sorted((a, b) => b.value.compareTo(a.value));

    if (allEntries.length <= 4) return allEntries;

    // Keep the top 3
    final topThree = allEntries.take(3).toList();

    // Sum up the value of all the remaining categories
    final otherSum = allEntries.skip(3).map((e) => e.value).reduce((a, b) => a + b);

    // Add the "Other" category to the end
    topThree.add(MapEntry('other_label', otherSum));

    return topThree;
  }

  Future<List<DailyChartPoint>> _fetchAndAggregateDailyPoints(DateTime month, String currencyCode) async {
    final range = DateTime(month.year, month.month + 1, 0); // Determine exact total days in targeted month
    final totalDays = range.day;

    try {
      final uid = _repo.currentUid;
      if (uid.isEmpty) return [];

      // Query raw items matching timeframe constraints directly from firestore abstractions
      final transactions = await _repo.getMonthlyDataTransactions(month, currencyCode);

      // Create indexed intermediate maps for O(1) lookups
      final Map<int, double> dailyIncome = {};
      final Map<int, double> dailyExpenses = {};

      for (var tx in transactions) {
        final day = tx.date.day;
        final amount = _repo.exchangeService.fromBase(tx.baseAmount, currencyCode);

        if (tx.type == 'Income') {
          dailyIncome.update(day, (v) => v + amount, ifAbsent: () => amount);
        } else {
          dailyExpenses.update(day, (v) => v + amount, ifAbsent: () => amount);
        }
      }

      // Generate a contiguous array mapping every calendar day of the month sequentially
      return List.generate(totalDays, (index) {
        final day = index + 1;
        return DailyChartPoint(
          day: day,
          income: dailyIncome[day] ?? 0.0,
          expenses: dailyExpenses[day] ?? 0.0,
        );
      });
    } catch (e) {
      debugPrint("Error creating trend points matrix: $e");
      return [];
    }
  }

  @override
  void dispose() {
    _monthController.close();
    super.dispose();
  }

}