import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/state_models/category_spending.dart';
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

  Stream<MonthlyData> get currentMonthlyDataStream {
    return Rx.combineLatest2(
      _monthController.stream,
      _currencyProvider.currencyStream,
      (month, currency) => _repo.streamMonthlyData(month, currency),
    ).switchMap((stream) => stream);
  }

  Stream<List<DailyChartPoint>> get dailyTrendStream {
    return currentMonthlyDataStream.map((monthlyData) {
      final totalDays = DateTime(monthlyData.month.year, monthlyData.month.month + 1, 0).day;
      
      final Map<int, double> dailyIncome = {};
      final Map<int, double> dailyExpenses = {};

      for (var tx in monthlyData.rawTransactions) {
        final day = tx.date.day;
        final amount = _repo.exchangeService.fromBase(tx.baseAmount, _currencyProvider.currentCurrency);

        if (tx.type == 'Income') {
          dailyIncome.update(day, (v) => v + amount, ifAbsent: () => amount);
        } else {
          dailyExpenses.update(day, (v) => v + amount, ifAbsent: () => amount);
        }
      }

      return List.generate(totalDays, (index) {
        final day = index + 1;
        return DailyChartPoint(
          day: day,
          income: dailyIncome[day] ?? 0.0,
          expenses: dailyExpenses[day] ?? 0.0,
        );
      });
    });
  }

  Stream<List<MonthlyData>> get reviewDataStream {
    return Rx.combineLatest2(
      _monthController.stream,
      _currencyProvider.currencyStream,
      (month, currency) => _repo.streamReviewData(month, currency),
    ).switchMap((stream) => stream);
  }

  Stream<List<CategorySpending>> get categorySpendingStream {
    return currentMonthlyDataStream.map((data) {
      final totalExpenses = data.expenses;
      
      // Map your cached breakdown into the CategorySpending format
      return data.categoryBreakdown.entries.map((entry) {
        return CategorySpending(
          category: Category(id: entry.key, name: entry.key), // Or resolve from Repo
          totalAmount: entry.value,
          percentage: totalExpenses > 0 ? (entry.value / totalExpenses) : 0,
        );
      }).toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    });
  }

  void changeMonth(DateTime newMonth) {
    _selectedMonth = newMonth;
    _monthController.add(newMonth);
    notifyListeners();
  }

  @override
  void dispose() {
    _monthController.close();
    super.dispose();
  }
}