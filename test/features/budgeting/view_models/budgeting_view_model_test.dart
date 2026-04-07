import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/features/budgeting/view_models/budgeting_view_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}
class MockMonthlyTransactionRepository extends Mock implements MonthlyTransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockLanguageProvider extends Mock implements LanguageProvider {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  late BudgetingViewModel viewModel;
  late MockBudgetRepository mockBudgetRepo;
  late MockMonthlyTransactionRepository mockTxRepo;
  late MockCategoryRepository mockCatRepo;
  late MockLanguageProvider mockLangProvider;


  late BehaviorSubject<List<Category>> categoriesSubject;
  late BehaviorSubject<List<Budget>> budgetsSubject;
  late BehaviorSubject<List<Transaction>> transactionsSubject;
  late BehaviorSubject<String> localeSubject;

  setUp(() {
    mockBudgetRepo = MockBudgetRepository();
    mockTxRepo = MockMonthlyTransactionRepository();
    mockCatRepo = MockCategoryRepository();
    mockLangProvider = MockLanguageProvider();

    categoriesSubject = BehaviorSubject<List<Category>>();
    budgetsSubject = BehaviorSubject<List<Budget>>();
    transactionsSubject = BehaviorSubject<List<Transaction>>();
    localeSubject = BehaviorSubject<String>();

    // Stub the methods and streams so they don't return null
    when(() => mockCatRepo.categoriesStream).thenAnswer((_) => categoriesSubject.stream);
    when(() => mockBudgetRepo.budgetsStream).thenAnswer((_) => budgetsSubject.stream);
    when(() => mockTxRepo.stream).thenAnswer((_) => transactionsSubject.stream);
    when(() => mockLangProvider.localeStream).thenAnswer((_) => localeSubject.stream);
    
    when(() => mockLangProvider.localeCode).thenReturn('en');
    
    // Stub the fetch methods since constructor calls them immediately
    when(() => mockBudgetRepo.fetchBudgets(any())).thenReturn(null);
    when(() => mockTxRepo.fetchForMonth(any())).thenReturn(null);
  });

  tearDown(() {
    categoriesSubject.close();
    budgetsSubject.close();
    transactionsSubject.close();
    localeSubject.close();
  });

  test('Initial state maps data correctly and calculates total budget', () async {
    viewModel = BudgetingViewModel(mockBudgetRepo, mockTxRepo, mockCatRepo, mockLangProvider);

    const testUserId = 'user_123';

    expect(viewModel.isLoading, true);

    categoriesSubject.add([
      Category(id: '1', name: 'Food'),
      Category(id: '2', name: 'Transport'),
    ]);
    
    budgetsSubject.add([
      Budget(id: 'budget_1', userId: testUserId, categoryId: '1', amount: 200.0, monthYear: 'April 2026'),
      Budget(id: 'budget_2', userId: testUserId, categoryId: '2', amount: 150.0, monthYear: 'April 2026'),
    ]);
    
    transactionsSubject.add([]);
    localeSubject.add('en');

    await Future.delayed(Duration.zero);

    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, null);
    expect(viewModel.currentState, isNotNull);
    
    expect(viewModel.currentState!.totalBudget, 350.0);
    
    expect(viewModel.currentState!.activeBudgetsCount, 2);
  });

  test('Streams emitting an error correctly updates error state', () async {
    // 1. ARRANGE
    viewModel = BudgetingViewModel(mockBudgetRepo, mockTxRepo, mockCatRepo, mockLangProvider);

    expect(viewModel.isLoading, true);
    expect(viewModel.errorMessage, null);

    // 2. ACT
    categoriesSubject.addError('Database connection timed out');

    await Future.delayed(Duration.zero);

    // 3. ASSERT
    expect(viewModel.isLoading, false);
    
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.errorMessage, contains('Database connection timed out'));
    
    expect(viewModel.currentState, isNull);
  });
}