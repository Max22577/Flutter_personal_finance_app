import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/features/dashboard/view_models/spending_chart_view_model.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';


class MockMonthlyTransactionRepository extends Mock implements MonthlyTransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late SpendingChartViewModel viewModel;
  late MockMonthlyTransactionRepository mockTxRepo;
  late MockCategoryRepository mockCatRepo;

  late BehaviorSubject<List<Transaction>> transactionsSubject;
  late BehaviorSubject<List<Category>> categoriesSubject;

  setUp(() {
    mockTxRepo = MockMonthlyTransactionRepository();
    mockCatRepo = MockCategoryRepository();

    transactionsSubject = BehaviorSubject<List<Transaction>>();
    categoriesSubject = BehaviorSubject<List<Category>>();

    // Stub the streams FIRST
    when(() => mockTxRepo.stream).thenAnswer((_) => transactionsSubject.stream);
    when(() => mockCatRepo.categoriesStream).thenAnswer((_) => categoriesSubject.stream);
  });

  tearDown(() {
    transactionsSubject.close();
    categoriesSubject.close();
  });

  group('Initial State -', () {
    test('starts with isLoading as true and empty data', () {
      viewModel = SpendingChartViewModel(mockTxRepo, mockCatRepo);

      expect(viewModel.isLoading, true);
      expect(viewModel.categoryData, isEmpty);
    });
  });

  group('Stream Updates -', () {
    test('filters income and aggregates expenses by category name', () async {
      viewModel = SpendingChartViewModel(mockTxRepo, mockCatRepo);

      // 1. ARRANGE
      final categories = [
        Category(id: 'cat_food', name: 'Food'),
        Category(id: 'cat_bills', name: 'Bills'),
      ];

      final now = DateTime.now();
      final transactions = [
        Transaction(id: '1', userId: 'u1', title: 'Lunch', amount: 15.0, date: now, type: 'Expense', categoryId: 'cat_food'),
        Transaction(id: '2', userId: 'u1', title: 'Dinner', amount: 25.0, date: now, type: 'Expense', categoryId: 'cat_food'),
        
        // One bill expense
        Transaction(id: '3', userId: 'u1', title: 'Power', amount: 100.0, date: now, type: 'Expense', categoryId: 'cat_bills'),
        
        // One income transaction (SHOULD BE IGNORED)
        Transaction(id: '4', userId: 'u1', title: 'Paycheck', amount: 2000.0, date: now, type: 'Income', categoryId: 'cat_food'),
      ];

      // 2. ACT
      categoriesSubject.add(categories);
      transactionsSubject.add(transactions);
      
      await Future.delayed(Duration.zero);

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      
      // We expect 'Food' to be 15 + 25 = 40.0
      expect(viewModel.categoryData['Food'], 40.0);
      
      // We expect 'Bills' to be 100.0
      expect(viewModel.categoryData['Bills'], 100.0);
      
      // We expect the 'Income' transaction to have been safely ignored
      expect(viewModel.categoryData.containsKey('Income'), false);
      expect(viewModel.categoryData.length, 2);
    });

    test('maps unknown category IDs to "Other" fallback', () async {
      viewModel = SpendingChartViewModel(mockTxRepo, mockCatRepo);

      // 1. ARRANGE
      final categories = [
        Category(id: 'cat_food', name: 'Food'),
      ];

      final transactions = [
        // Known category
        Transaction(id: '1', userId: 'u1', title: 'Lunch', amount: 15.0, date: DateTime.now(), type: 'Expense', categoryId: 'cat_food'),
        
        // Unknown category ID (not in categories list above)
        Transaction(id: '2', userId: 'u1', title: 'Some Mystery Purchase', amount: 50.0, date: DateTime.now(), type: 'Expense', categoryId: 'cat_unknown'),
      ];

      // 2. ACT
      categoriesSubject.add(categories);
      transactionsSubject.add(transactions);
      await Future.delayed(Duration.zero);

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      expect(viewModel.categoryData['Food'], 15.0);
      
      expect(viewModel.categoryData['Other'], 50.0);
    });
  });
}