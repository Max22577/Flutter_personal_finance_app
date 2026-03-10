import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import '../../../models/monthly_data.dart';

class DashboardViewModel extends ChangeNotifier {
  final MonthlyDataRepository _repo;
  StreamSubscription? _sub;

  MonthlyData? currentMonthData;
  MonthlyData? previousMonthData;
  bool isLoading = true;
  String? errorMessage;

  DashboardViewModel(this._repo) {
    _sub = _repo.comparisonStream.listen(
      (data) {
        currentMonthData = data['current'];
        previousMonthData = data['previous'];
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> retry() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    await _repo.refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}