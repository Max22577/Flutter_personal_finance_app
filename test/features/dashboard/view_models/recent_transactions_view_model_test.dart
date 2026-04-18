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
    when(() => mockRepo.getCategoryName(any())).thenAnswer((_) async => 'Test Category');
  });

  tearDown(() {
    transactionsSubject.close();
  });

  group('Initial State -', () {
    test('starts with isLoading as true and empty transactions', () {
      viewModel = RecentTransactionsViewModel(repo: mockRepo);
      expect(viewModel.isLoading, true);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.recentTransactions, isEmpty);
    });
  });

  group('Error Handling & Retry -', () {
    test('handles stream errors and populates errorMessage', () async {
      viewModel = RecentTransactionsViewModel(repo: mockRepo);

      transactionsSubject.addError(Exception('Firebase Timeout'));
      await Future.delayed(Duration.zero);

      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, contains('Connection to transactions lost'));
      expect(viewModel.recentTransactions, isEmpty);
    });

    test('retry() clears error and re-subscribes to stream', () async {
      viewModel = RecentTransactionsViewModel(repo: mockRepo);

      // error state
      transactionsSubject.addError(Exception('Initial Failure'));
      await Future.delayed(Duration.zero);
      expect(viewModel.errorMessage, isNotNull);

      // Retry
      viewModel.retry();

      // ASSERT: Should be loading again and error cleared
      expect(viewModel.isLoading, true);
      expect(viewModel.errorMessage, isNull);

      // Emit valid data
      final t1 = Transaction(id: '1', userId: 'u1', title: 'T1', amount: 10, date: DateTime.now(), type: 'Expense', categoryId: 'c1');
      transactionsSubject.add([t1]);
      await Future.delayed(Duration.zero);

      // ASSERT: Success
      expect(viewModel.isLoading, false);
      expect(viewModel.recentTransactions.length, 1);
    });

    test('handles errors during category name fetching', () async {
      viewModel = RecentTransactionsViewModel(repo: mockRepo);
      
      // ARRANGE: Repository fails when fetching the name
      when(() => mockRepo.getCategoryName(any())).thenThrow(Exception('Metadata fetch failed'));
      
      final t1 = Transaction(id: '1', userId: 'u1', title: 'T1', amount: 10, date: DateTime.now(), type: 'Expense', categoryId: 'c1');

      // ACT
      transactionsSubject.add([t1]);
      await Future.delayed(Duration.zero);

      // ASSERT
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, contains('Failed to process transactions'));
    });
  });

  group('Stream Updates -', () {
    final now = DateTime.now();

    test('sorts transactions and fetches category names', () async {
      viewModel = RecentTransactionsViewModel(repo: mockRepo);

      final t1 = Transaction(id: '1', userId: 'u1', title: 'T1', amount: 10, date: now, type: 'Expense', categoryId: 'c1');
      
      // ACT
      transactionsSubject.add([t1]);
      await Future.delayed(Duration.zero);

      // ASSERT
      expect(viewModel.isLoading, false);
      expect(viewModel.recentTransactions.first.id, '1');
      // Verify the async category fetch was called
      verify(() => mockRepo.getCategoryName('c1')).called(1);
      expect(viewModel.getCategoryName('c1'), 'Test Category');
    });
  });
}