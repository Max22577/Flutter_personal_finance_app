import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../models/monthly_data.dart';
import '../services/monthly_data_service.dart';

class MonthlyDataRepository {
  final MonthlyDataService _service = MonthlyDataService();
  
  final _monthlyComparisonSubject = BehaviorSubject<Map<String, MonthlyData?>>();

  StreamSubscription? _sub;

  MonthlyDataRepository() {
    _init();
  }

  void _init() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);

    _sub = Rx.combineLatest2(
      _service.streamMonthlyData(currentMonth),
      _service.streamMonthlyData(previousMonth),
      (MonthlyData current, MonthlyData previous) => {
        'current': current,
        'previous': previous,
      },
    ).listen(
      (data) => _monthlyComparisonSubject.add(data),
      onError: (e) => _monthlyComparisonSubject.addError(e),
    );
  }

  Stream<Map<String, MonthlyData?>> get comparisonStream => _monthlyComparisonSubject.stream;

  Future<List<MonthlyData?>> getReviewData(DateTime currentMonth) async {
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    
    return await Future.wait([
      _service.getMonthlyData(currentMonth),
      _service.getMonthlyData(previousMonth),
    ]);
  }

  Future<void> refresh() async {
    _sub?.cancel();
    _init();
    await _monthlyComparisonSubject.first.timeout(const Duration(seconds: 5));
  }

  void dispose() {
    _sub?.cancel();
    _monthlyComparisonSubject.close();
  }
}