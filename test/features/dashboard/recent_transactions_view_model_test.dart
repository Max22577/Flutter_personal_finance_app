import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/features/dashboard/view_models/recent_transactions_view_model.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late RecentTransactionsViewModel viewModel;
  late MockTransactionRepository mockRepo;
  late BehaviorSubject<List<Transaction>> transactionsSubject;

  setUp(() {
    mockRepo = MockTransactionRepository();
    transactionsSubject = BehaviorSubject<List<Transaction>>();

    when(() => mockRepo.transactionsStream).thenAnswer((_) => transactionsSubject.stream);
  });

  tearDown(() {
    transactionsSubject.close();
  });

  group('Initial State -', () {
    test('starts with isLoading as true and empty transactions', () {
      viewModel = RecentTransactionsViewModel(repo: mockRepo);

      expect(viewModel.isLoading, true);
      expect(viewModel.recentTransactions, isEmpty);
    });
  });

  group('Stream Updates -', () {
    final now = DateTime.now();

    test('sorts transactions by date descending and takes the default limit of 5', () async {
      viewModel = RecentTransactionsViewModel(repo: mockRepo);

      // 1. ARRANGE
      final t1 = Transaction(id: '1', userId: 'u1', title: 'Oldest', amount: 10, date: now.subtract(const Duration(days: 5)), type: 'Expense', categoryId: 'c1');
      final t2 = Transaction(id: '2', userId: 'u1', title: 'Newest', amount: 20, date: now, type: 'Expense', categoryId: 'c1');
      final t3 = Transaction(id: '3', userId: 'u1', title: 'Mid 1', amount: 30, date: now.subtract(const Duration(days: 1)), type: 'Expense', categoryId: 'c1');
      final t4 = Transaction(id: '4', userId: 'u1', title: 'Mid 2', amount: 40, date: now.subtract(const Duration(days: 2)), type: 'Expense', categoryId: 'c1');
      final t5 = Transaction(id: '5', userId: 'u1', title: 'Mid 3', amount: 50, date: now.subtract(const Duration(days: 3)), type: 'Expense', categoryId: 'c1');
      final t6 = Transaction(id: '6', userId: 'u1', title: 'Mid 4', amount: 60, date: now.subtract(const Duration(days: 4)), type: 'Expense', categoryId: 'c1');

      // 2. ACT
      transactionsSubject.add([t1, t3, t5, t2, t4, t6]);
      await Future.delayed(const Duration(milliseconds: 10));

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      
      expect(viewModel.recentTransactions.length, 5);
      
      expect(viewModel.recentTransactions.first.id, '2');
      
      expect(viewModel.recentTransactions.last.id, '5');
    });

    test('respects custom maxItems parameter when provided', () async {
      viewModel = RecentTransactionsViewModel(repo: mockRepo, maxItems: 2);

      // 1. ARRANGE
      final transactions = [
        Transaction(id: '1', userId: 'u1', title: 'T1', amount: 10, date: now, type: 'Expense', categoryId: 'c1'),
        Transaction(id: '2', userId: 'u1', title: 'T2', amount: 20, date: now.subtract(const Duration(days: 1)), type: 'Expense', categoryId: 'c1'),
        Transaction(id: '3', userId: 'u1', title: 'T3', amount: 30, date: now.subtract(const Duration(days: 2)), type: 'Expense', categoryId: 'c1'),
      ];

      // 2. ACT
      transactionsSubject.add(transactions);
      await Future.delayed(Duration.zero);

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      
      expect(viewModel.recentTransactions.length, 2);
      expect(viewModel.recentTransactions.first.id, '1');
      expect(viewModel.recentTransactions.last.id, '2');
    });

    test('handles stream errors gracefully by turning off loading', () async {
      viewModel = RecentTransactionsViewModel(repo: mockRepo);

      // 1. ARRANGE
      final error = Exception('Database corrupted');

      // 2. ACT
      transactionsSubject.addError(error);
      await Future.delayed(Duration.zero);

      // 3. ASSERT
      expect(viewModel.isLoading, false);
      expect(viewModel.recentTransactions, isEmpty);
    });
  });
}