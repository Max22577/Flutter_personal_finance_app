import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/services/monthly_data_service.dart';
import 'package:personal_fin/models/monthly_data.dart';

class MockMonthlyDataService extends Mock implements MonthlyDataService {}

void main() {
  late MonthlyDataRepository repository;
  late MockMonthlyDataService mockService;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    mockService = MockMonthlyDataService();
    
    when(() => mockService.streamMonthlyData(any()))
        .thenAnswer((_) => Stream.value(MonthlyData(month: DateTime(2026, 4), income: 0, expenses: 0)));
  });

  group('getReviewData -', () {
    test('fetches current and previous month data in parallel', () async {
      // 1. ARRANGE
      final currentMonth = DateTime(2026, 4, 1);
      final previousMonth = DateTime(2026, 3, 1);

      final dummyCurrent = MonthlyData(month: currentMonth, income: 5000, expenses: 3000);
      final dummyPrevious = MonthlyData(month: previousMonth, income: 4000, expenses: 2000);

      // Stub the service futures
      when(() => mockService.getMonthlyData(currentMonth))
          .thenAnswer((_) async => dummyCurrent);
      when(() => mockService.getMonthlyData(previousMonth))
          .thenAnswer((_) async => dummyPrevious);

      repository = MonthlyDataRepository(service: mockService);

      // 2. ACT
      final results = await repository.getReviewData(currentMonth);

      // 3. ASSERT
      expect(results.length, 2);
      expect(results[0], dummyCurrent);
      expect(results[1], dummyPrevious);
      
      // Verify the repository actually asked the service for both months
      verify(() => mockService.getMonthlyData(currentMonth)).called(1);
      verify(() => mockService.getMonthlyData(previousMonth)).called(1);
    });
  });

  group('comparisonStream -', () {
    test('combines current and previous month streams successfully', () async {
      // 1. ARRANGE
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final previousMonth = DateTime(now.year, now.month - 1);

      final dummyCurrent = MonthlyData(month: currentMonth, income: 1000, expenses: 500);
      final dummyPrevious = MonthlyData(month: previousMonth, income: 800, expenses: 400);

      // Stub the specific streams the repository will ask for in _init()
      when(() => mockService.streamMonthlyData(currentMonth))
          .thenAnswer((_) => Stream.value(dummyCurrent));
      when(() => mockService.streamMonthlyData(previousMonth))
          .thenAnswer((_) => Stream.value(dummyPrevious));

      // 2. ACT
      repository = MonthlyDataRepository(service: mockService);

      // 3. ASSERT
      final emissions = await repository.comparisonStream.first;

      expect(emissions['current'], dummyCurrent);
      expect(emissions['previous'], dummyPrevious);
    });
  });
}