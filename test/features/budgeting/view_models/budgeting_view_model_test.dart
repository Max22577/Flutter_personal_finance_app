import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/features/budgeting/view_models/budgeting_view_model.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:personal_fin/models/budgeting_state.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';



class MockBudgetRepository extends Mock implements BudgetRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late BudgetingViewModel viewModel;
  late MockBudgetRepository mockBudgetRepo;
  late MockTransactionRepository mockTxRepo;
  late MockCategoryRepository mockCatRepo;
  late MockExchangeRateService mockExchangeService;

  final now = DateTime.now();
  final formattedCurrentMonth = DateFormat('MMMM yyyy').format(now);

  final testCategories = [
    Category(id: 'cat_food', name: 'Food & Groceries'),
    Category(id: 'cat_rent', name: 'Rent & Living'),
    Category(id: 'cat_salary', name: 'Main Salary'), // Income category - should be filtered out
  ];

  final testBudgets = [
    Budget(id: 'cat_food_$formattedCurrentMonth', userId: 'uid_123', categoryId: 'cat_food', amount: 500.0, baseAmount: 500.0, currency: 'USD', monthYear: formattedCurrentMonth),
    Budget(id: 'cat_rent_$formattedCurrentMonth', userId: 'uid_123', categoryId: 'cat_rent', amount: 1200.0, baseAmount: 1200.0, currency: 'USD', monthYear: formattedCurrentMonth),
  ];

  final testTransactions = [
    Transaction(id: 't1', userId: 'uid_123', title: 'Supermarket', amount: 150.0, currency: 'USD', baseAmount: 150.0, type: 'Expense', categoryId: 'cat_food', date: now),
    Transaction(id: 't2', userId: 'uid_123', title: 'Fast Food', amount: 50.0, currency: 'USD', baseAmount: 50.0, type: 'Expense', categoryId: 'cat_food', date: now),
    Transaction(id: 't3', userId: 'uid_123', title: 'Paycheck', amount: 3000.0, currency: 'USD', baseAmount: 3000.0, type: 'Income', categoryId: 'cat_salary', date: now),
  ];

  setUpAll(() {
    registerFallbackValue(Budget(
      id: '',
      userId: '',
      categoryId: '',
      amount: 0.0,
      baseAmount: 0.0,
      currency: 'USD',
      monthYear: '',
    ));
  });

  setUp(() {
    mockBudgetRepo = MockBudgetRepository();
    mockTxRepo = MockTransactionRepository();
    mockCatRepo = MockCategoryRepository();
    mockExchangeService = MockExchangeRateService();

    // Default structural stubs
    when(() => mockBudgetRepo.uid).thenReturn('uid_123');
    when(() => mockBudgetRepo.updateMonthYear(any())).thenReturn(null);
    when(() => mockExchangeService.toBase(any(), any())).thenAnswer((inv) => inv.positionalArguments[0] as double);
  });

  group('BudgetingViewModel Tests', () {
    
    test('Constructor should sync initial date downward to underlying repositories immediately', () {
      // Act
      viewModel = BudgetingViewModel(
        mockBudgetRepo,
        mockTxRepo,
        mockCatRepo,
        exchangeService: mockExchangeService,
      );

      // Assert
      verify(() => mockBudgetRepo.updateMonthYear(formattedCurrentMonth)).called(1);
    });

    group('stateStream Processing Engines', () {
      test('should correctly aggregate budgets, filter income categories, and compute multi-source math maps', () async {
        // Arrange
        final catController = BehaviorSubject<List<Category>>.seeded(testCategories);
        final budgetController = BehaviorSubject<List<Budget>>.seeded(testBudgets);
        final txController = BehaviorSubject<List<Transaction>>.seeded(testTransactions);

        when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => catController.stream);
        when(() => mockBudgetRepo.budgetsStream).thenAnswer((_) => budgetController.stream);
        when(() => mockTxRepo.transactionsStream).thenAnswer((_) => txController.stream);

        viewModel = BudgetingViewModel(mockBudgetRepo, mockTxRepo, mockCatRepo, exchangeService: mockExchangeService);

        // Act & Assert
        expect(
          viewModel.stateStream,
          emits(isA<BudgetingState>()
              .having((s) => s.totalCategoryCount, 'filters out income keywords', 2) // Food, Rent (Salary dropped)
              .having((s) => s.totalBudget, 'sums total budget allocations', 1700.0) // 500 + 1200
              .having((s) => s.activeBudgetsCount, 'counts active budget structures', 2)
              .having((s) => s.monthYear, 'matches system localized date context strings', formattedCurrentMonth)
              .having((s) => s.spendingMap['cat_food'], 'aggregates expense metrics group calculations', 200.0) // 150 + 50
              .having((s) => s.spendingMap.containsKey('cat_salary'), 'skips income matching rules from spending aggregates', false)
              .having((s) => s.budgetMap['cat_rent'], 'maps category budget arrays accurately', 1200.0)),
        );

        await catController.close();
        await budgetController.close();
        await txController.close();
      });
    });

    group('Date & Structural Coordination Updates', () {
      test('setDate should rewrite tracking strings and signal listener pipelines to refresh view frames', () {
        when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => Stream.empty());
        when(() => mockBudgetRepo.budgetsStream).thenAnswer((_) => Stream.empty());
        when(() => mockTxRepo.transactionsStream).thenAnswer((_) => Stream.empty());

        viewModel = BudgetingViewModel(mockBudgetRepo, mockTxRepo, mockCatRepo, exchangeService: mockExchangeService);

        final targetDate = DateTime(2026, 12, 25);
        final expectedFormattedDate = DateFormat('MMMM yyyy').format(targetDate);

        int uiNotificationCount = 0;
        viewModel.addListener(() => uiNotificationCount++);

        // Act
        viewModel.setDate(targetDate);

        // Assert
        expect(viewModel.selectedDate, targetDate);
        expect(uiNotificationCount, 1); // Confirms notifyListeners() fired to broadcast changes
        verify(() => mockBudgetRepo.updateMonthYear(expectedFormattedDate)).called(1); // Fired inside constructor AND setDate
      });

      test('refreshData should run deliberate delayed padding timers before executing re-sync loops', () async {
        when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => Stream.empty());
        when(() => mockBudgetRepo.budgetsStream).thenAnswer((_) => Stream.empty());
        when(() => mockTxRepo.transactionsStream).thenAnswer((_) => Stream.empty());

        viewModel = BudgetingViewModel(mockBudgetRepo, mockTxRepo, mockCatRepo, exchangeService: mockExchangeService);

        int uiNotificationCount = 0;
        viewModel.addListener(() => uiNotificationCount++);

        // Act
        final refreshFuture = viewModel.refreshData();

        // Verification that the 800ms delay protects against instant execution
        expect(uiNotificationCount, 0);

        await refreshFuture;

        // Assert
        expect(uiNotificationCount, 1);
        verify(() => mockBudgetRepo.updateMonthYear(formattedCurrentMonth)).called(2); // Constructor + Refresh data call
      });
    });

    group('Database Payload Mutations', () {
      test('updateBudget should compound accurate composite IDs and pass complete data entities downward', () async {
        when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => Stream.empty());
        when(() => mockBudgetRepo.budgetsStream).thenAnswer((_) => Stream.empty());
        when(() => mockTxRepo.transactionsStream).thenAnswer((_) => Stream.empty());
        when(() => mockBudgetRepo.setBudget(any())).thenAnswer((_) => Future.value());

        viewModel = BudgetingViewModel(mockBudgetRepo, mockTxRepo, mockCatRepo, exchangeService: mockExchangeService);

        // Act
        await viewModel.setBudget('cat_travel', 250.0, 'EUR');

        // Assert
        verify(() => mockBudgetRepo.setBudget(any(that: isA<Budget>()
          .having((b) => b.id, 'calculates the composite primary key mapping pattern', 'cat_travel_$formattedCurrentMonth')
          .having((b) => b.categoryId, 'category assignment', 'cat_travel')
          .having((b) => b.amount, 'raw entry value amount tracking', 250.0)
          .having((b) => b.currency, 'currency property validation', 'EUR')
          .having((b) => b.monthYear, 'month context binding alignment verification', formattedCurrentMonth)
        ))).called(1);
      });
    });
  });
}