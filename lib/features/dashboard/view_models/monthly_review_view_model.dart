import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/models/monthly_data.dart';

class MonthlyReviewViewModel extends ChangeNotifier {
  final MonthlyDataRepository _repo;
  
  MonthlyReviewViewModel(this._repo);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MonthlyData? _currentMonthData;
  MonthlyData? get currentMonthData => _currentMonthData;

  MonthlyData? _previousMonthData;
  MonthlyData? get previousMonthData => _previousMonthData;

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

  Future<void> loadData(DateTime month) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repo.getReviewData(month);
      _currentMonthData = results[0];
      _previousMonthData = results[1];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}