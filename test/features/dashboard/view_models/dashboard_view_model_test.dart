import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

class MockMonthlyDataRepository extends Mock implements MonthlyDataRepository {}
void main() {
  late DashboardViewModel viewModel;
  late MockMonthlyDataRepository mockRepo;
  late BehaviorSubject<Map<String, MonthlyData>> comparisonSubject;

  setUpAll(() async {
    // Load calendar data for the DateFormats used in MonthlyData
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    mockRepo = MockMonthlyDataRepository();
    comparisonSubject = BehaviorSubject<Map<String, MonthlyData>>();

    when(() => mockRepo.comparisonStream).thenAnswer((_) => comparisonSubject.stream);
    when(() => mockRepo.refresh()).thenAnswer((_) async {});

    viewModel = DashboardViewModel(mockRepo); 
  });

  tearDown(() {
    comparisonSubject.close();
  });

  test('initial state is loading', () {
    expect(viewModel.isLoading, true);
    expect(viewModel.currentMonthData, null);
    expect(viewModel.previousMonthData, null);
    expect(viewModel.errorMessage, null);
  });

  test('receives data and updates state', () async {
    final currentData = MonthlyData(month: DateTime(2026, 6), income: 5000, expenses: 3000);
    final previousData = MonthlyData(month: DateTime(2026, 5), income: 4500, expenses: 2500);

    // Act
    comparisonSubject.add({
      'current': currentData,
      'previous': previousData,
    });
  
    await Future.delayed(Duration.zero); 

    // Assert
    expect(viewModel.isLoading, false);
    expect(viewModel.currentMonthData, currentData);
    expect(viewModel.previousMonthData, previousData);
    expect(viewModel.errorMessage, null);
  });

  test('handles errors from stream', () async {
    final error = Exception('Failed to load data');

    when(() => mockRepo.comparisonStream).thenAnswer((_) => Stream.error(error));

    viewModel = DashboardViewModel(mockRepo);
    await Future.delayed(Duration.zero); 

    // 3. Assert
    expect(viewModel.isLoading, false);
    expect(viewModel.currentMonthData, null);
    expect(viewModel.previousMonthData, null);
    expect(viewModel.errorMessage, error.toString());
  });
}