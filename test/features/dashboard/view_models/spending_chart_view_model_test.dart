import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/features/dashboard/view_models/spending_chart_view_model.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';


class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late SpendingChartViewModel viewModel;
  late MockTransactionRepository mockTxRepo;
  late MockCategoryRepository mockCatRepo;
  late MockExchangeRateService mockExchangeService;

  final sampleCategories = [
    Category(id: 'cat_food', name: 'Food & Dining'),
    Category(id: 'cat_rent', name: 'Housing & Rent'),
  ];

  final sampleTransactions = [
    // Two matching Expense records for Food
    Transaction(id: 't1', userId: 'u1', title: 'Groceries', amount: 150.0, currency: 'USD', baseAmount: 150.0, type: 'Expense', categoryId: 'cat_food', date: DateTime.now()),
    Transaction(id: 't2', userId: 'u1', title: 'Dinner out', amount: 50.0, currency: 'USD', baseAmount: 50.0, type: 'Expense', categoryId: 'cat_food', date: DateTime.now()),
    
    // One matching Expense record for Rent
    Transaction(id: 't3', userId: 'u1', title: 'May Rent', amount: 1200.0, currency: 'USD', baseAmount: 1200.0, type: 'Expense', categoryId: 'cat_rent', date: DateTime.now()),
    
    // An Income transaction that should be ignored entirely
    Transaction(id: 't4', userId: 'u1', title: 'Paycheck', amount: 3000.0, currency: 'USD', baseAmount: 3000.0, type: 'Income', categoryId: 'cat_salary', date: DateTime.now()),
    
    // An Expense transaction pointing to a category ID not present in the category list
    Transaction(id: 't5', userId: 'u1', title: 'Mystery Store', amount: 75.0, currency: 'USD', baseAmount: 75.0, type: 'Expense', categoryId: 'cat_deleted', date: DateTime.now()),
  ];

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockCatRepo = MockCategoryRepository();
    mockExchangeService = MockExchangeRateService();

    when(() => mockExchangeService.fromBase(any(), any()))
        .thenAnswer((inv) => inv.positionalArguments[0] as double);
  });

  group('SpendingChartViewModel Tests', () {
    test('should listen to combined streams, aggregate expenses by category name, skip income, and fallback to Other', () async {
      // Arrange - Seed both underlying streams before creating the viewmodel
      final txController = BehaviorSubject<List<Transaction>>.seeded(sampleTransactions);
      final catController = BehaviorSubject<List<Category>>.seeded(sampleCategories);
      final currController = BehaviorSubject<String>.seeded('USD');

      when(() => mockTxRepo.monthlyTransactionsStream).thenAnswer((_) => txController.stream);
      when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => catController.stream);

      // Act
      viewModel = SpendingChartViewModel(
        mockTxRepo, 
        mockCatRepo, 
        mockExchangeService, 
        currencyStream: currController.stream
      );
      await Future.delayed(Duration.zero); // Flush microtasks to allow combineLatest2 to resolve

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);

      final data = viewModel.categoryData;
      
      // Verification rules
      expect(data.keys.length, 3); // 'Food & Dining', 'Housing & Rent', and 'Other' (Income skipped)
      expect(data['Food & Dining'], 200.0); // 150.0 + 50.0 combined
      expect(data['Housing & Rent'], 1200.0);
      expect(data['Other'], 75.0); // 'cat_deleted' maps cleanly into 'Other' fallback bucket
      expect(data.containsKey('Income'), false); // Paycheck completely filtered out

      await txController.close();
      await catController.close();
    });

    test('should emit custom error text if either combining stream throws an error', () async {
      // Arrange - Set up transactions to fire an error up the pipe
      final currController = BehaviorSubject<String>.seeded('USD');
      when(() => mockTxRepo.monthlyTransactionsStream).thenAnswer((_) => Stream<List<Transaction>>.error('Database unreachable'));
      when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => Stream.value(sampleCategories));

      // Act
      viewModel = SpendingChartViewModel(
        mockTxRepo, 
        mockCatRepo, 
        mockExchangeService, 
        currencyStream: currController.stream
      );
      await Future.delayed(Duration.zero);

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.categoryData, isEmpty);
      expect(viewModel.errorMessage, equals("Could not load chart data. Please check your connection."));
    });

    test('retry should correctly kickstart stream pipelines back to initial processing states', () async {
      // Arrange
      final currController = BehaviorSubject<String>.seeded('USD');
      when(() => mockTxRepo.monthlyTransactionsStream).thenAnswer((_) => Stream.value([]));
      when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => Stream.value([]));

      viewModel = SpendingChartViewModel(
        mockTxRepo, 
        mockCatRepo, 
        mockExchangeService, 
        currencyStream: currController.stream
      );
      await Future.delayed(Duration.zero);

      // Artificially flip properties to confirm refresh resets them
      expect(viewModel.isLoading, false);

      // Act
      viewModel.retry();

      // Assert
      expect(viewModel.isLoading, true);
      expect(viewModel.errorMessage, null);
    });

    test('dispose should close the reactive subscription immediately to prevent stream leak points', () async {
      // Arrange
      final txController = BehaviorSubject<List<Transaction>>();
      final catController = BehaviorSubject<List<Category>>();
      final currController = BehaviorSubject<String>.seeded('USD');

      when(() => mockTxRepo.monthlyTransactionsStream).thenAnswer((_) => txController.stream);
      when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => catController.stream);

      viewModel = SpendingChartViewModel(
        mockTxRepo, 
        mockCatRepo, 
        mockExchangeService, 
        currencyStream: currController.stream
      );

      // Act & Assert
      expect(txController.hasListener, true);
      expect(catController.hasListener, true);

      viewModel.dispose();

      // Assert listeners are successfully dropped
      expect(txController.hasListener, false);
      expect(catController.hasListener, false);

      await txController.close();
      await catController.close();
    });
  });
}