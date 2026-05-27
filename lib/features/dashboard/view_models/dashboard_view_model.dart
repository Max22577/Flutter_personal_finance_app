import 'dart:async';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import '../../../models/monthly_data.dart';

class DashboardViewModel  {
  final MonthlyDataRepository _repo;

  MonthlyData? currentMonthData;
  MonthlyData? previousMonthData;
  bool isLoading = true;
  String? errorMessage;

  DashboardViewModel(this._repo);

  Stream<Map<String, MonthlyData?>> get monthlyDataStream => _repo.comparisonStream;
}