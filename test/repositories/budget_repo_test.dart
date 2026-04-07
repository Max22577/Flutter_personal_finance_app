import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_test/flutter_test.dart'; 
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/budget.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late BudgetRepository repository;
  late MockFirestoreService mockFirestoreService;
  late BehaviorSubject<List<Budget>> serviceStreamSubject;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    serviceStreamSubject = BehaviorSubject<List<Budget>>();
    
    repository = BudgetRepository(service: mockFirestoreService);
  });

  tearDown(() {
    serviceStreamSubject.close();
    repository.dispose();
  });

  group('fetchBudgets -', () {
    const testMonthYear = '2026-04';

    test('subscribes to firestore stream and pipes data to repository stream', () async {
      // 1. ARRANGE
      final dummyBudgets = [
        Budget(id: 'b1', userId: 'u1', categoryId: 'c1', amount: 200.0, monthYear: testMonthYear),
      ];

      when(() => mockFirestoreService.streamBudgets(monthYear: testMonthYear))
          .thenAnswer((_) => serviceStreamSubject.stream);

      // 2. ACT
      repository.fetchBudgets(testMonthYear);
      
      serviceStreamSubject.add(dummyBudgets);
      
      // 3. ASSERT
      // Grab the first event emitted by the repository's exposed stream
      final result = await repository.budgetsStream.first;

      expect(result, dummyBudgets);
      expect(result.length, 1);
      expect(result.first.amount, 200.0);
      
      // Verify that the repo actually asked Firestore for the correct month
      verify(() => mockFirestoreService.streamBudgets(monthYear: testMonthYear)).called(1);
    });
  });
}