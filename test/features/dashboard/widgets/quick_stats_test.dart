import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/dashboard/widgets/stats_card.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/features/dashboard/widgets/quick_stats.dart';
import '../../../helpers/test_helpers.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepo;
  late TestDependencyManager deps;

  setUp(() {
    mockRepo = MockTransactionRepository();
    deps = TestDependencyManager();

    // Standard stub for the repository stream
    when(() => mockRepo.transactionsStream).thenAnswer((_) => Stream.value([]));
  });

  group('QuickStats & StatCard Widget Tests -', () {
    
    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(deps.wrap(
        const QuickStats(),
        extraProviders: [
          Provider<TransactionRepository>.value(value: mockRepo),
        ],
      ));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('renders PageView with two StatCards after loading', (tester) async {
      await tester.pumpWidget(deps.wrap(
        const QuickStats(),
        extraProviders: [
          Provider<TransactionRepository>.value(value: mockRepo),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);

      expect(find.byType(StatCard), findsAtLeastNWidgets(1));
    });

    testWidgets('StatCard correctly calculates and displays net balance', (tester) async {
      const income = 5000.0;
      const expense = 2000.0;
      const expectedNet = "3000.00"; 

      await tester.pumpWidget(deps.wrap(
        const StatCard(
          title: 'Test Month',
          income: income,
          expenses: expense,
        ),
      ));

      await tester.pumpAndSettle();

      // Verify Title (Helper mocks translate to uppercase)
      expect(find.text('TEST MONTH'), findsOneWidget);
      
      // Verify Net Balance (income - expense = 3000)
      expect(find.textContaining(expectedNet), findsOneWidget);
    });

    testWidgets('StatCard shows improved comparison when net is higher than previous', (tester) async {
      await tester.pumpWidget(deps.wrap(
        StatCard(
          title: 'Current',
          income: 1000,
          expenses: 200, // Net = 800
          previousMonthData: MonthlyData(month: DateTime(2026, 3, 12), income: 500, expenses: 100), // Previous Net = 400
        ),
      ));

      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

      expect(avatar.backgroundColor, isNot(Colors.red));

      expect(find.textContaining('IMPROVED'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      // Difference is 400
      expect(find.textContaining('400.00'), findsOneWidget);
    });
  });
}