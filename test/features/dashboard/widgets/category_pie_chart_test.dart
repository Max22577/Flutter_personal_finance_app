import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/features/dashboard/widgets/category_pie_chart.dart';
import '../../../helpers/test_helpers.dart';

class MockMonthlyTransactionRepo extends Mock implements MonthlyTransactionRepository {}
class MockCategoryRepo extends Mock implements CategoryRepository {}

void main() {
  late MockMonthlyTransactionRepo mockTxRepo;
  late MockCategoryRepo mockCatRepo;
  late TestDependencyManager deps;

  late BehaviorSubject<List<Transaction>> transactionsSubject;
  late BehaviorSubject<List<Category>> categoriesSubject;

  setUp(() {
    mockTxRepo = MockMonthlyTransactionRepo();
    mockCatRepo = MockCategoryRepo();
    deps = TestDependencyManager();

    transactionsSubject = BehaviorSubject<List<Transaction>>();
    categoriesSubject = BehaviorSubject<List<Category>>();

    when(() => mockTxRepo.stream).thenAnswer((_) => transactionsSubject.stream);
    when(() => mockCatRepo.categoriesStream).thenAnswer((_) => categoriesSubject.stream);
  });

  tearDown(() {
    transactionsSubject.close();
    categoriesSubject.close();
  });

  group('CategoryPieChart UI Tests -', () {
    testWidgets('transitions from loading to displaying data correctly', (tester) async {
      await tester.pumpWidget(deps.wrap(
        const CategoryPieChart(),
        extraProviders: [
          Provider<MonthlyTransactionRepository>.value(value: mockTxRepo),
          Provider<CategoryRepository>.value(value: mockCatRepo),
        ],
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final categories = [Category(id: '1', name: 'Food')];
      final transactions = [
        Transaction(
          id: 'tx1', 
          userId: 'u1', 
          title: 'Lunch', 
          amount: 50.0, 
          date: DateTime.now(), 
          type: 'Expense', 
          categoryId: '1'
        ),
      ];

      categoriesSubject.add(categories);
      transactionsSubject.add(transactions);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text("Monthly Spending Breakdown"), findsOneWidget);
      
      expect(find.text('Food'), findsOneWidget);

      expect(find.textContaining('50'), findsOneWidget);
    });

    testWidgets('shows "Other" for transactions with missing categories', (tester) async {
      await tester.pumpWidget(deps.wrap(
        const CategoryPieChart(),
        extraProviders: [
          Provider<MonthlyTransactionRepository>.value(value: mockTxRepo),
          Provider<CategoryRepository>.value(value: mockCatRepo),
        ],
      ));

      categoriesSubject.add([]); 
      transactionsSubject.add([
        Transaction(
          id: 'tx1', 
          userId: 'u1', 
          title: 'Misc', 
          amount: 100.0, 
          date: DateTime.now(), 
          type: 'Expense', 
          categoryId: 'non_existent'
        ),
      ]);

      await tester.pumpAndSettle();

      expect(find.text('Other'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('renders empty state when only income exists', (tester) async {
       await tester.pumpWidget(deps.wrap(
        const CategoryPieChart(),
        extraProviders: [
          Provider<MonthlyTransactionRepository>.value(value: mockTxRepo),
          Provider<CategoryRepository>.value(value: mockCatRepo),
        ],
      ));

      categoriesSubject.add([Category(id: '1', name: 'Bonus')]);
      transactionsSubject.add([
        Transaction(
          id: 'tx1', 
          userId: 'u1', 
          title: 'Salary', 
          amount: 5000.0, 
          date: DateTime.now(), 
          type: 'Income', 
          categoryId: '1'
        ),
      ]);

      await tester.pumpAndSettle();

      expect(find.text("No expenses this month"), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });
  });
}