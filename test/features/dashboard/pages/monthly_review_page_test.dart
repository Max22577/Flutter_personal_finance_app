import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/dashboard/pages/monthly_review_page.dart';
import 'package:personal_fin/features/dashboard/widgets/monthly_review.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/models/monthly_data.dart';
import '../../../helpers/test_helpers.dart';
import '../view_models/dashboard_view_model_test.dart';

class MockMonthlyDataRepo extends Mock implements MonthlyDataRepository {}

void main() {
  late MockMonthlyDataRepository mockRepo;
  late TestDependencyManager deps;
  final testMonth = DateTime(2026, 4);

  setUp(() {
    mockRepo = MockMonthlyDataRepository();
    deps = TestDependencyManager();
  });

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  group('MonthlyReviewPage UI -', () {
    testWidgets('renders top categories and groups "Other" correctly', (tester) async {
      
      // ARRANGE
      final currentData = MonthlyData(
        month: testMonth,
        income: 5000,
        expenses: 2000,
        categoryBreakdown: {
          'Food': 1000.0,  // Top 1
          'Rent': 500.0,   // Top 2
          'Power': 300.0,  // Top 3
          'Water': 150.0,  // Groups into Other
          'Gas': 50.0,     // Groups into Other
        },
      );
      final previousData = MonthlyData(month: DateTime(2026, 3), income: 4000, expenses: 1500);

      when(() => mockRepo.getReviewData(testMonth))
          .thenAnswer((_) async => [currentData, previousData]);

      // ACT
      await tester.pumpWidget(deps.wrap(
        MonthlyReviewPage(month: testMonth),
        extraProviders: [
          Provider<MonthlyDataRepository>.value(value: mockRepo),
        ],
      ));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump();

      await tester.pump(const Duration(seconds: 700));

      await tester.pumpAndSettle();

      // Check for top 3 categories in the Bar Chart
      expect(find.text('Rent'), findsNWidgets(2));
      expect(find.text('Food'), findsNWidgets(2));
      expect(find.text('Power'), findsNWidgets(2));

      // Check that 'Water' and 'Gas' are NOT shown individually
      expect(find.text('Water'), findsNothing);
      
      // Check for the "Other" grouping 
      expect(find.text('other_label'), findsWidgets); 
      
      expect(find.textContaining('200'), findsNWidgets(2));
    });

    testWidgets('shows error state and retries successfully', (tester) async {
      // ARRANGE
      when(() => mockRepo.getReviewData(any())).thenThrow(Exception('Timeout'));

      await tester.pumpWidget(deps.wrap(
        MonthlyReviewPage(month: testMonth),
        extraProviders: [Provider<MonthlyDataRepository>.value(value: mockRepo)],
      ));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('err_load_monthly'), findsOneWidget);

      // ACT
      final successData = MonthlyData(month: testMonth, income: 1000, expenses: 500);
      when(() => mockRepo.getReviewData(testMonth))
          .thenAnswer((_) async => [successData, successData]);

      await tester.tap(find.text('try_again'));
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('visual_breakdown'), findsOneWidget);
    });

    testWidgets('tapping MonthlyReview opens detailed bottom sheet', (tester) async {
      final currentData = MonthlyData(month: testMonth, income: 5000, expenses: 2000);
      when(() => mockRepo.getReviewData(testMonth))
          .thenAnswer((_) async => [currentData, currentData]);

      await tester.pumpWidget(deps.wrap(
        MonthlyReviewPage(month: testMonth),
        extraProviders: [Provider<MonthlyDataRepository>.value(value: mockRepo)],
      ));
      await tester.pumpAndSettle();

      // Tap the card (MonthlyReview widget)
      await tester.tap(find.byType(MonthlyReview));
      await tester.pumpAndSettle(); 

      // Verify Modal content
      expect(find.textContaining('summary_title'), findsOneWidget);
      expect(find.text('income_label'), findsOneWidget);
      expect(find.textContaining('5000'), findsNWidgets(2));
    });
  });
}