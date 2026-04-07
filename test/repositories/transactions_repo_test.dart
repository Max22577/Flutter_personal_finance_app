import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_test/flutter_test.dart'; 
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late TransactionRepository repository;
  late MockFirestoreService mockFirestoreService;
  late BehaviorSubject<List<Transaction>> serviceStreamSubject;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    serviceStreamSubject = BehaviorSubject<List<Transaction>>();

    when(() => mockFirestoreService.streamTransactions())
        .thenAnswer((_) => serviceStreamSubject.stream);

    repository = TransactionRepository(service: mockFirestoreService);
  });

  tearDown(() {
    serviceStreamSubject.close();
    repository.dispose();
  });

  group('transactionsStream -', () {
    test('subscribes to firestore stream and pipes data to repository stream', () async {
      // 1. ARRANGE
      final dummyTransactions = [
        Transaction(id: 't1', userId: 'u1', categoryId: 'c1', title: 'Money for lunch', amount: 50.0,type: 'Expense', date: DateTime.now()),
      ];

      // Tell Mocktail to return our BehaviorSubject's stream when called
      when(() => mockFirestoreService.streamTransactions())
          .thenAnswer((_) => serviceStreamSubject.stream);

      // 2. ACT
      final stream = repository.transactionsStream;
      
      // Simulate Firestore emitting data
      serviceStreamSubject.add(dummyTransactions);
      
      // 3. ASSERT
      // Grab the first event emitted by the repository's exposed stream
      final result = await stream.first;

      expect(result, dummyTransactions);
      expect(result.length, 1);
      expect(result.first.amount, 50.0);
      
      // Verify that the repo actually asked Firestore for transactions
      verify(() => mockFirestoreService.streamTransactions()).called(1);
    });
  });

  group('CRUD operations -', () {
    test('add transaction', () {
      // ARRANGE
      final newTransaction = Transaction(id: 't2', userId: 'u1', categoryId: 'c2', title: 'Groceries', amount: 100.0,type: 'Expense', date: DateTime.now());
      when(() => mockFirestoreService.addTransaction(newTransaction))
          .thenAnswer((_) async => Future.value());

      // ACT
      repository.addTransaction(newTransaction);

      // ASSERT
      verify(() => mockFirestoreService.addTransaction(newTransaction)).called(1);
    });

    test('update transaction', () {
      // ARRANGE
      final updatedTransaction = Transaction(id: 't1', userId: 'u1', categoryId: 'c1', title: 'Money for lunch', amount: 60.0,type: 'Expense', date: DateTime.now());
      when(() => mockFirestoreService.updateTransaction(updatedTransaction))
          .thenAnswer((_) async => Future.value());

      // ACT
      repository.updateTransaction(updatedTransaction);

      // ASSERT
      verify(() => mockFirestoreService.updateTransaction(updatedTransaction)).called(1);
    });

    test('delete transaction', () {
      // ARRANGE
      const transactionId = 't1';
      when(() => mockFirestoreService.deleteTransaction(transactionId))
          .thenAnswer((_) async => Future.value());

      // ACT
      repository.deleteTransaction(transactionId);

      // ASSERT
      verify(() => mockFirestoreService.deleteTransaction(transactionId)).called(1);
    });

  });
}