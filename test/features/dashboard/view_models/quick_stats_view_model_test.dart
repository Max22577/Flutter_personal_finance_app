import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/features/dashboard/view_models/quick_stats_view_model.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';


class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late QuickStatsViewModel viewModel;
  late MockTransactionRepository mockTxRepo;

  // Dynamically derive current and previous month timestamps relative to when tests run
  final now = DateTime.now();
  final currentMonthDate = DateTime(now.year, now.month, 15); // Mid-current-month
  final lastMonthDate = DateTime(now.year, now.month - 1, 15); // Mid-last-month

  final sampleTransactions = [
    // Current Month Transactions
    Transaction(id: 't1', userId: 'u1', title: 'Salary', amount: 5000.0, currency: 'USD', baseAmount: 5000.0, type: 'Income', categoryId: 'c1', date: currentMonthDate),
    Transaction(id: 't2', userId: 'u1', title: 'Rent', amount: 1200.0, currency: 'USD', baseAmount: 1200.0, type: 'Expense', categoryId: 'c2', date: currentMonthDate),
    Transaction(id: 't3', userId: 'u1', title: 'Food', amount: 300.0, currency: 'USD', baseAmount: 300.0, type: 'Expense', categoryId: 'c3', date: currentMonthDate),
    
    // Last Month Transactions
    Transaction(id: 't4', userId: 'u1', title: 'Side Hustle', amount: 800.0, currency: 'USD', baseAmount: 800.0, type: 'Income', categoryId: 'c4', date: lastMonthDate),
    Transaction(id: 't5', userId: 'u1', title: 'Car Repair', amount: 450.0, currency: 'USD', baseAmount: 450.0, type: 'Expense', categoryId: 'c5', date: lastMonthDate),
  ];

  setUp(() {
    mockTxRepo = MockTransactionRepository();
  });

  group('QuickStatsViewModel Tests', () {
    test('should listen to transactionsStream and accurately aggregate income and expenses for current and last month', () async {
      // Arrange - Prepare stream before instantiating the constructor
      final streamController = BehaviorSubject<List<Transaction>>.seeded(sampleTransactions);
      when(() => mockTxRepo.transactionsStream).thenAnswer((_) => streamController.stream);

      // Act
      viewModel = QuickStatsViewModel(mockTxRepo);
      
      // Let the microtask loop push stream data through the constructor subscription
      await Future.delayed(Duration.zero);

      // Assert
      expect(viewModel.isLoading, false);
      
      // Current Month Verification
      expect(viewModel.currentMonthIncome, 5000.0);
      expect(viewModel.currentMonthExpenses, 1500.0); // 1200 + 300

      // Last Month Verification
      expect(viewModel.lastMonthIncome, 800.0);
      expect(viewModel.lastMonthExpenses, 450.0);

      await streamController.close();
    });

    test('should reset metrics to exactly 0.0 when stream fires completely empty transaction payloads', () async {
      // Arrange
      final streamController = BehaviorSubject<List<Transaction>>.seeded(sampleTransactions);
      when(() => mockTxRepo.transactionsStream).thenAnswer((_) => streamController.stream);

      viewModel = QuickStatsViewModel(mockTxRepo);
      await Future.delayed(Duration.zero);
      
      // Sanity check: verify values exist first
      expect(viewModel.currentMonthIncome, 5000.0);

      // Act - Simulate adding a completely blank transaction list update wave
      streamController.add([]);
      await Future.delayed(Duration.zero);

      // Assert - Check if everything resets back down cleanly
      expect(viewModel.currentMonthIncome, 0.0);
      expect(viewModel.currentMonthExpenses, 0.0);
      expect(viewModel.lastMonthIncome, 0.0);
      expect(viewModel.lastMonthExpenses, 0.0);

      await streamController.close();
    });

    test('should safely decouple streams and cancel subscriptions on view model lifecycle dispose', () async {
      // Arrange
      final streamController = BehaviorSubject<List<Transaction>>();
      when(() => mockTxRepo.transactionsStream).thenAnswer((_) => streamController.stream);

      viewModel = QuickStatsViewModel(mockTxRepo);

      // Act & Assert
      expect(streamController.hasListener, true);
      
      viewModel.dispose();
      
      // Asserts that no listener leaks are hanging around background execution layers
      expect(streamController.hasListener, false);

      await streamController.close();
    });
  });
}