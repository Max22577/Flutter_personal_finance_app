import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/dashboard/widgets/monthly_review.dart';
import 'package:personal_fin/models/monthly_data.dart';
import '../../../helpers/test_helpers.dart';

class MockMonthlyData extends Mock implements MonthlyData {}

void main() {
  late TestDependencyManager deps;
  late MockMonthlyData mockCurrentMonth;
  late MockMonthlyData mockPreviousMonth;

  setUp(() {
    deps = TestDependencyManager();
    mockCurrentMonth = MockMonthlyData();
    mockPreviousMonth = MockMonthlyData();

    // Setup default valid responses for the current month mock
    when(() => mockCurrentMonth.formattedMonth).thenReturn('March 2026');
    when(() => mockCurrentMonth.income).thenReturn(5000.0);
    when(() => mockCurrentMonth.expenses).thenReturn(3000.0);
    when(() => mockCurrentMonth.net).thenReturn(2000.0);
    
    // Setup default valid responses for the previous month mock
    when(() => mockPreviousMonth.formattedMonth).thenReturn('February 2026');
    when(() => mockPreviousMonth.income).thenReturn(4000.0);
    when(() => mockPreviousMonth.expenses).thenReturn(3500.0);
    when(() => mockPreviousMonth.net).thenReturn(500.0);

    // Mock the comparison math
    when(() => mockCurrentMonth.percentageChangeFrom(any())).thenReturn(15.5);
  });

  setUpAll(() {
    registerFallbackValue(MockMonthlyData());
  });

  group('MonthlyReview Widget -', () {
    testWidgets('renders header, income, expenses, and net balances correctly', (tester) async {
      await tester.pumpWidget(deps.wrap(
        MonthlyReview(
          monthlyData: mockCurrentMonth,
          showComparison: false, 
        ),
      ));

      // Wait for TweenAnimationBuilders (1200ms) to finish
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('MARCH 2026'), findsOneWidget); // Uppercase from UI logic

      // Check labels (mock lang translates to UPPERCASE)
      expect(find.text('INCOME'), findsOneWidget);
      expect(find.text('EXPENSE'), findsOneWidget);
      expect(find.text('NET BALANCE'), findsOneWidget);

      // Check values (using the simple formatting from our mock formatter)
      expect(find.textContaining('5000'), findsOneWidget);
      expect(find.textContaining('3000'), findsOneWidget);
      expect(find.textContaining('2000'), findsOneWidget);
    });

    testWidgets('shows savings efficiency section when income is greater than 0', (tester) async {
      await tester.pumpWidget(deps.wrap(
        MonthlyReview(monthlyData: mockCurrentMonth),
      ));

      await tester.pumpAndSettle();

      // Income is 5000, expenses 3000. Savings ratio = (5000-3000)/5000 = 0.4 (40%)
      expect(find.text('SAVINGS EFFICIENCY'), findsOneWidget);
      expect(find.text('40.0%'), findsOneWidget);
    });

    testWidgets('hides savings efficiency section when income is 0', (tester) async {
      when(() => mockCurrentMonth.income).thenReturn(0.0);
      when(() => mockCurrentMonth.expenses).thenReturn(1000.0);
      when(() => mockCurrentMonth.net).thenReturn(-1000.0);

      await tester.pumpWidget(deps.wrap(
        MonthlyReview(monthlyData: mockCurrentMonth),
      ));

      await tester.pumpAndSettle();

      expect(find.text('SAVINGS EFFICIENCY'), findsNothing);
    });

    testWidgets('renders comparison tile when previousMonthData is provided', (tester) async {
      await tester.pumpWidget(deps.wrap(
        MonthlyReview(
          monthlyData: mockCurrentMonth,
          previousMonthData: mockPreviousMonth,
          showComparison: true,
        ),
      ));

      await tester.pumpAndSettle();

      // Positive trend expectations
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
      expect(find.text('PERF UP'), findsOneWidget);
      
      // Checking the compiled string: '15.5% BETTER THAN LAST MONTH'
      expect(find.textContaining('15.5%'), findsOneWidget);
      expect(find.textContaining('BETTER'), findsOneWidget);

      // Checking previous month net output
      expect(find.textContaining('PREVIOUS:'), findsOneWidget);
      expect(find.text('500.00'), findsOneWidget); // Previous net
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(deps.wrap(
        MonthlyReview(
          monthlyData: mockCurrentMonth,
          onTap: () => wasTapped = true,
        ),
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(wasTapped, isTrue);
    });
  });
}