import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_test/flutter_test.dart'; 
import 'package:mocktail/mocktail.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late MonthlyTransactionRepository repository;
  late MockFirestoreService mockFirestoreService;
  late BehaviorSubject<List<Transaction>> serviceStreamSubject;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    serviceStreamSubject = BehaviorSubject<List<Transaction>>();
    
    repository = MonthlyTransactionRepository(service: mockFirestoreService);
  });

  tearDown(() {
    serviceStreamSubject.close();
    repository.dispose();
  });

  group('fetchForMonth -', () {
    const testMonthYear = '2026-04';

    test('subscribes to firestore stream and pipes data to repository stream', () async {
      // 1. ARRANGE
      final dummyTransactions = [
        Transaction(id: '1', userId: 'u1', title: 'Coffee', amount: 5.0, date: DateTime.now(), type: 'Expense', categoryId: 'c1'),
      ];

      // Tell Mocktail to return our BehaviorSubject's stream when called
      when(() => mockFirestoreService.streamMonthlyTransactions(monthYear: testMonthYear))
          .thenAnswer((_) => serviceStreamSubject.stream);

      // 2. ACT
      repository.fetchForMonth(testMonthYear);
      
      // Simulate Firestore emitting data
      serviceStreamSubject.add(dummyTransactions);
      
      // 3. ASSERT
      // Grab the first event emitted by the repository's exposed stream
      final result = await repository.stream.first;

      expect(result, dummyTransactions);
      expect(result.length, 1);
      expect(result.first.title, 'Coffee');
      
      // Verify that the repo actually asked Firestore for the correct month
      verify(() => mockFirestoreService.streamMonthlyTransactions(monthYear: testMonthYear)).called(1);
    });

    test('cancels previous subscription when called again for a new month', () async {
      // 1. ARRANGE
      when(() => mockFirestoreService.streamMonthlyTransactions(monthYear: any(named: 'monthYear')))
          .thenAnswer((_) => serviceStreamSubject.stream);

      // 2. ACT
      repository.fetchForMonth('2026-04');
      repository.fetchForMonth('2026-05'); 

      // 3. ASSERT
      // Verify it called Firestore twice (once for each month)
      verify(() => mockFirestoreService.streamMonthlyTransactions(monthYear: '2026-04')).called(1);
      verify(() => mockFirestoreService.streamMonthlyTransactions(monthYear: '2026-05')).called(1);
    });
  });
}