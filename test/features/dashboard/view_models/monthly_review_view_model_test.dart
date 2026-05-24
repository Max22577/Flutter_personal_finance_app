import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/features/dashboard/view_models/monthly_review_view_model.dart';
import 'package:personal_fin/models/monthly_data.dart';


class MockMonthlyDataRepository extends Mock implements MonthlyDataRepository {}
class MockCurrencyProvider extends Mock implements CurrencyProvider {}

void main() {
  late MonthlyReviewViewModel viewModel;
  late MockMonthlyDataRepository mockMonthlyDataRepo;
  late MockCurrencyProvider mockCurrencyProvider;

  setUp(() {
    mockMonthlyDataRepo = MockMonthlyDataRepository();
    mockCurrencyProvider = MockCurrencyProvider();
  
    // Default: Always return 'USD'
    when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
    viewModel = MonthlyReviewViewModel(mockMonthlyDataRepo, mockCurrencyProvider);
  });

  group('MonthlyReviewViewModel Tests', () {
    final testMonth = DateTime(2026, 5);

    final sampleCurrentData = MonthlyData(
      month: testMonth,
      income: 5000.0,
      expenses: 2000.0,
      transactionCount: 10,
      categoryBreakdown: {
        'Rent': 1000.0,
        'Groceries': 400.0,
        'Dining': 300.0,
        'Utilities': 200.0,
        'Entertainment': 100.0,
      },
    );

    final samplePreviousData = MonthlyData(
      month: DateTime(2026, 4),
      income: 5000.0,
      expenses: 1800.0,
      transactionCount: 8,
      categoryBreakdown: {'Rent': 1000.0},
    );

    group('loadData Async Operations', () {
      test('should populate current and previous data properties successfully upon repo resolve', () async {
        // Arrange
        when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
        when(() => mockMonthlyDataRepo.getReviewData(testMonth, 'USD'))
            .thenAnswer((_) => Future.value([sampleCurrentData, samplePreviousData]));

        int notificationCount = 0;
        viewModel.addListener(() => notificationCount++);

        // Act
        final future = viewModel.loadData(testMonth);

        // Verify it sets loading to true immediately
        expect(viewModel.isLoading, true);
        expect(viewModel.errorMessage, null);

        await future;

        // Assert
        expect(viewModel.isLoading, false);
        expect(viewModel.currentMonthData, sampleCurrentData);
        expect(viewModel.previousMonthData, samplePreviousData);
        expect(notificationCount, 2); // Fired at start and finish
      });

      test('should intercept execution exceptions and surface an error message cleanly to the layout', () async {
        // Arrange
        when(() => mockMonthlyDataRepo.getReviewData(testMonth, mockCurrencyProvider.currentCurrency))
            .thenThrow(Exception('Timeout fetching financial metrics'));

        // Act
        await viewModel.loadData(testMonth);

        // Assert
        expect(viewModel.isLoading, false);
        expect(viewModel.currentMonthData, null);
        expect(viewModel.errorMessage, contains('Timeout fetching financial metrics'));
      });
    });

    test('should fetch data using the current currency from CurrencyProvider', () async {
      // Arrange
      when(() => mockCurrencyProvider.currentCurrency).thenReturn('EUR');
      when(() => mockMonthlyDataRepo.getReviewData(testMonth, 'EUR'))
          .thenAnswer((_) => Future.value([sampleCurrentData, samplePreviousData]));

      // Act
      await viewModel.loadData(testMonth);

      // Assert
      verify(() => mockMonthlyDataRepo.getReviewData(testMonth, 'EUR')).called(1);
      expect(viewModel.currentMonthData, sampleCurrentData);
    });

    group('Business Logic Properties & Math Rules', () {
      test('savingsRate should evaluate to 0.0 if data is completely missing or income is zero', () {
        // No data loaded
        expect(viewModel.savingsRate, 0.0);

        // Setup broken data chunk with zero income
        when(() => mockMonthlyDataRepo.getReviewData(testMonth, mockCurrencyProvider.currentCurrency)).thenAnswer((_) => Future.value([
              MonthlyData(month: testMonth, income: 0.0, expenses: 100.0, transactionCount: 1, categoryBreakdown: {}),
              samplePreviousData,
            ]));
        
        expect(viewModel.savingsRate, 0.0);
      });

      test('savingsRate should compute percentages accurately and clamp limits cleanly', () async {
        // Arrange (Net is 5000 - 2000 = 3000. 3000 / 5000 = 0.6)
        when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
        when(() => mockMonthlyDataRepo.getReviewData(testMonth, 'USD'))
            .thenAnswer((_) => Future.value([sampleCurrentData, samplePreviousData]));

        // Act
        await viewModel.loadData(testMonth);

        // Assert
        expect(viewModel.savingsRate, 0.6);
      });
    });

    group('topSpendingCategories Parsing Logic', () {
      test('should return empty list if data context is not initialized yet', () {
        expect(viewModel.topSpendingCategories, isEmpty);
      });

      test('should sort categories descending and safely combine remaining entries into an other_label bracket', () async {
        // Arrange
        when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
        when(() => mockMonthlyDataRepo.getReviewData(testMonth, 'USD'))
            .thenAnswer((_) => Future.value([sampleCurrentData, samplePreviousData]));

        // Act
        await viewModel.loadData(testMonth);
        final categories = viewModel.topSpendingCategories;

        // Assert
        // Top 3 categories + 1 "Other" combined bucket = 4 entries max
        expect(categories.length, 4);

        // 1. Highest item must be first
        expect(categories[0].key, 'Rent');
        expect(categories[0].value, 1000.0);

        // 2. Second item
        expect(categories[1].key, 'Groceries');
        expect(categories[1].value, 400.0);

        // 3. Third item
        expect(categories[2].key, 'Dining');
        expect(categories[2].value, 300.0);

        // 4. "Other" item containing remaining keys combined (Utilities: 200 + Entertainment: 100 = 300.0)
        expect(categories[3].key, 'other_label');
        expect(categories[3].value, 300.0);
      });

      test('should skip aggregating other categories if total individual entries do not exceed 4 items', () async {
        // Arrange - Small list with only 2 categories total
        final smallData = MonthlyData(
          month: testMonth,
          income: 2000.0,
          expenses: 600.0,
          transactionCount: 2,
          categoryBreakdown: {'Food': 400.0, 'Transport': 200.0},
        );
        
        when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
        when(() => mockMonthlyDataRepo.getReviewData(testMonth, 'USD'))
            .thenAnswer((_) => Future.value([smallData, samplePreviousData]));

        // Act
        await viewModel.loadData(testMonth);
        final categories = viewModel.topSpendingCategories;

        // Assert
        expect(categories.length, 2);
        expect(categories.any((e) => e.key == 'other_label'), false);
      });
    });
  });
}