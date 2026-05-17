import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:rxdart/rxdart.dart';


class MockMonthlyDataRepository extends Mock implements MonthlyDataRepository {}

void main() {
  late DashboardViewModel viewModel;
  late MockMonthlyDataRepository mockMonthlyDataRepo;

  final sampleCurrentData = MonthlyData(
    month: DateTime(2026, 5),
    income: 6000.0,
    expenses: 2500.0,
    transactionCount: 12,
    categoryBreakdown: {'Food': 400.0},
  );

  final samplePreviousData = MonthlyData(
    month: DateTime(2026, 4),
    income: 5500.0,
    expenses: 3000.0,
    transactionCount: 15,
    categoryBreakdown: {'Rent': 1000.0},
  );

  setUp(() {
    mockMonthlyDataRepo = MockMonthlyDataRepository();
  });

  group('DashboardViewModel Tests', () {
    test('should listen to comparisonStream on init and populate data properties accurately', () async {
      // Arrange - Prepare stream payload before instantiating the constructor
      final streamController = BehaviorSubject<Map<String, MonthlyData>>.seeded({
        'current': sampleCurrentData,
        'previous': samplePreviousData,
      });
      when(() => mockMonthlyDataRepo.comparisonStream).thenAnswer((_) => streamController.stream);

      // Act
      viewModel = DashboardViewModel(mockMonthlyDataRepo);
      
      // Allow microtask queue to process stream subscription data allocations
      await Future.delayed(Duration.zero);

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      expect(viewModel.currentMonthData?.income, 6000.0);
      expect(viewModel.previousMonthData?.expenses, 3000.0);

      await streamController.close();
    });

    test('should capture error state messages gracefully when repository stream throws', () async {
      // Arrange
      when(() => mockMonthlyDataRepo.comparisonStream)
          .thenAnswer((_) => Stream<Map<String, MonthlyData>>.error('Database Connection Refused'));

      // Act
      viewModel = DashboardViewModel(mockMonthlyDataRepo);
      await Future.delayed(Duration.zero);

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.currentMonthData, null);
      expect(viewModel.errorMessage, contains('Database Connection Refused'));
    });

    test('retry should reset states back to processing configurations instantly', () async {
      // Arrange
      when(() => mockMonthlyDataRepo.comparisonStream)
          .thenAnswer((_) => Stream<Map<String, MonthlyData>>.empty());
      
      viewModel = DashboardViewModel(mockMonthlyDataRepo);
      viewModel.isLoading = false;
      viewModel.errorMessage = 'Prior Error';

      int notificationCount = 0;
      viewModel.addListener(() => notificationCount++);

      // Act
      await viewModel.retry();

      // Assert
      expect(viewModel.isLoading, true);
      expect(viewModel.errorMessage, null);
      expect(notificationCount, 1);
    });

    test('dispose should close the underlying reactive data pipeline subscription safely', () async {
      // Arrange
      final streamController = BehaviorSubject<Map<String, MonthlyData>>();
      when(() => mockMonthlyDataRepo.comparisonStream).thenAnswer((_) => streamController.stream);

      viewModel = DashboardViewModel(mockMonthlyDataRepo);

      // Act & Assert
      expect(streamController.hasListener, true);
      
      viewModel.dispose();
      
      // Verification that the stream is no longer being actively listened to by this VM
      expect(streamController.hasListener, false);

      await streamController.close();
    });
  });
}