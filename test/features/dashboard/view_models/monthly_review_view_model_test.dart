import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/features/dashboard/view_models/monthly_review_view_model.dart';
import 'package:personal_fin/models/monthly_data.dart';

class MockMonthlyDataRepository extends Mock implements MonthlyDataRepository {}

void main() {
  late MonthlyReviewViewModel viewModel;
  late MockMonthlyDataRepository mockRepo;

  setUpAll(() async {
    // Required since MonthlyData uses DateFormat inside it
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    mockRepo = MockMonthlyDataRepository();
    viewModel = MonthlyReviewViewModel(mockRepo);
  });

  group('Initial State -', () {
    test('starts with correct default values', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      expect(viewModel.currentMonthData, null);
      expect(viewModel.previousMonthData, null);
    });
  });

  group('loadData -', () {
    final testMonth = DateTime(2026, 4);
    final dummyCurrent = MonthlyData(month: testMonth, income: 5000, expenses: 3000);
    final dummyPrevious = MonthlyData(month: DateTime(2026, 3), income: 4000, expenses: 2000);

    test('sets data correctly on successful repository fetch', () async {
      // 1. ARRANGE
      when(() => mockRepo.getReviewData(testMonth))
          .thenAnswer((_) async => [dummyCurrent, dummyPrevious]);

      // 2. ACT
      final future = viewModel.loadData(testMonth);
      
      expect(viewModel.isLoading, true);

      await future;

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      expect(viewModel.currentMonthData, dummyCurrent);
      expect(viewModel.previousMonthData, dummyPrevious);
      expect(viewModel.errorMessage, null);
    });

    test('captures error message when repository fails', () async {
      // 1. ARRANGE
      final error = Exception('Network timeout');
      when(() => mockRepo.getReviewData(testMonth)).thenThrow(error);

      // 2. ACT
      await viewModel.loadData(testMonth);

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      expect(viewModel.currentMonthData, null);
      expect(viewModel.errorMessage, error.toString());
    });
  });

  group('savingsRate Getter -', () {
    test('returns 0.0 when data is null or income is zero', () {
      // Case 1: Data is null
      expect(viewModel.savingsRate, 0.0);

      // Case 2: Income is zero
      final zeroIncome = MonthlyData(month: DateTime(2026, 4), income: 0, expenses: 100);
      
      when(() => mockRepo.getReviewData(any()))
          .thenAnswer((_) async => [zeroIncome, zeroIncome]);
          
      // Wait for it to apply
      viewModel.loadData(DateTime(2026, 4));

      expect(viewModel.savingsRate, 0.0);
    });

    test('calculates and clamps the rate accurately', () async {
      // If income is 1000 and expenses are 400, net is 600. 600 / 1000 = 0.6
      final goodData = MonthlyData(month: DateTime(2026, 4), income: 1000, expenses: 400);
      
      when(() => mockRepo.getReviewData(any()))
          .thenAnswer((_) async => [goodData, goodData]);
          
      await viewModel.loadData(DateTime(2026, 4));

      expect(viewModel.savingsRate, 0.6);
    });
  });

  group('topSpendingCategories Getter -', () {
    test('returns empty list if no data is loaded', () {
      expect(viewModel.topSpendingCategories, []);
    });

    test('returns sorted entries when there are 4 or fewer categories', () async {
      final data = MonthlyData(
        month: DateTime(2026, 4),
        income: 1000,
        expenses: 500,
        categoryBreakdown: {
          'Bills': 100.0,
          'Food': 300.0, // Should be first
          'Transit': 50.0,
        },
      );

      when(() => mockRepo.getReviewData(any())).thenAnswer((_) async => [data, data]);
      await viewModel.loadData(DateTime(2026, 4));

      final results = viewModel.topSpendingCategories;

      expect(results.length, 3);
      expect(results[0].key, 'Food'); // Highest value
      expect(results[2].key, 'Transit'); // Lowest value
    });

    test('groups overflowing categories into "other_label" after top 3', () async {
      final data = MonthlyData(
        month: DateTime(2026, 4),
        income: 1000,
        expenses: 500,
        categoryBreakdown: {
          'Rent': 500.0,  // 1st
          'Food': 200.0,  // 2nd
          'Power': 100.0, // 3rd
          'Water': 30.0,  // Goes into "Other"
          'Gas': 20.0,    // Goes into "Other"
        },
      );

      when(() => mockRepo.getReviewData(any())).thenAnswer((_) async => [data, data]);
      await viewModel.loadData(DateTime(2026, 4));

      final results = viewModel.topSpendingCategories;

      // Should cut down to top 3 + 1 combined group = 4 items
      expect(results.length, 4);
      expect(results[0].key, 'Rent');
      expect(results[1].key, 'Food');
      expect(results[2].key, 'Power');
      
      // The 4th element should be our combined fallback
      expect(results[3].key, 'other_label');
      expect(results[3].value, 50.0); 
    });
  });
}