import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/dashboard/view_models/quick_stats_view_model.dart';
import 'package:rxdart/rxdart.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late QuickStatsViewModel viewModel;
  late MockTransactionRepository mockRepo;
  late BehaviorSubject<List<Transaction>> transactionsSubject;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    mockRepo = MockTransactionRepository();
    transactionsSubject = BehaviorSubject<List<Transaction>>();

    when(() => mockRepo.transactionsStream).thenAnswer((_) => transactionsSubject.stream);  
  });

  tearDown(() {
    transactionsSubject.close();
  });

  group('Initial State -', () {
    test('starts with correct default values', () {
      viewModel = QuickStatsViewModel(mockRepo);

      expect(viewModel.currentMonthIncome, 0);
      expect(viewModel.currentMonthExpenses, 0);
      expect(viewModel.lastMonthIncome, 0);
      expect(viewModel.lastMonthExpenses, 0);
      expect(viewModel.isLoading, true);
    });
  });

  group('Stream Updates -', () {
    final now = DateTime.now();
    
    final currentMonthDate = DateTime(now.year, now.month, 10);
    final lastMonthDate = DateTime(now.year, now.month - 1, 10);

    test('calculates stats correctly for current month transactions', () async {
      // 1. ARRANGE
      viewModel = QuickStatsViewModel(mockRepo); 

      final transactions = [
        Transaction(id: '1', userId: 'u1', title: 'Paycheck', amount: 1000, date: currentMonthDate, type: 'Income', categoryId: 'c1'),
        Transaction(id: '2', userId: 'u1', title: 'Groceries', amount: 500, date: currentMonthDate, type: 'Expense', categoryId: 'c2'),
      ];

      // 2. ACT
      transactionsSubject.add(transactions);
      await Future.delayed(Duration.zero); 

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      expect(viewModel.currentMonthIncome, 1000.0);
      expect(viewModel.currentMonthExpenses, 500.0);
      expect(viewModel.lastMonthIncome, 0.0);
      expect(viewModel.lastMonthExpenses, 0.0);
    });

    test('calculates stats correctly for last month transactions', () async {
      // 1. ARRANGE
      viewModel = QuickStatsViewModel(mockRepo);

      final transactions = [
        Transaction(id: '3', userId: 'u1', title: 'Last Month Paycheck', amount: 2000, date: lastMonthDate, type: 'Income', categoryId: 'c1'),
        Transaction(id: '4', userId: 'u1', title: 'Last Month Rent', amount: 1200, date: lastMonthDate, type: 'Expense', categoryId: 'c2'),
      ];

      // 2. ACT
      transactionsSubject.add(transactions);
      await Future.delayed(Duration.zero);

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      expect(viewModel.currentMonthIncome, 0.0);
      expect(viewModel.currentMonthExpenses, 0.0);
      expect(viewModel.lastMonthIncome, 2000.0);
      expect(viewModel.lastMonthExpenses, 1200.0);
    });
  });
}