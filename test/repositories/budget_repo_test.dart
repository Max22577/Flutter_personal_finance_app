import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_auth/firebase_auth.dart';



class MockIFirestoreService extends Mock implements IFirestoreService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late BudgetRepository repository;
  late MockIFirestoreService mockFirestoreService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(FieldFilter('test', FilterOperator.isEqualTo, 'test'));
  });

  setUp(() {
    mockFirestoreService = MockIFirestoreService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('user_789');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

    repository = BudgetRepository(service: mockFirestoreService, auth: mockAuth);
  });

  group('BudgetRepository Tests', () {
    final sampleBudgets = [
      Budget(id: 'b1', userId: 'user_789', categoryId: 'cat_food', amount: 500.0, baseAmount: 500.0, currency: 'USD', monthYear: '05-2026'),
      Budget(id: 'b2', userId: 'user_789', categoryId: 'cat_rent', amount: 1200.0, baseAmount: 1200.0, currency: 'USD', monthYear: '05-2026'),
    ];

    group('budgetsStream Operations', () {
      test('should emit filtered budgets when user changes the month text controller', () async {
        // Arrange
        when(() => mockFirestoreService.streamCollection<Budget>(
              collectionPath: any(named: 'collectionPath'),
              builder: any<Budget Function(Map<String, dynamic>)>(named: 'builder'),
              filters: any(named: 'filters'), 
            )).thenAnswer((_) => Stream.value(sampleBudgets));

        // Switch to a dynamic Future expectation to prevent race condition timeouts
        final streamFuture = repository.budgetsStream.first;

        // Act - Trigger update in UI/controller state
        repository.updateMonthYear('05-2026');

        // Assert
        final result = await streamFuture;
        expect(result.length, 2);
        expect(result.first.monthYear, '05-2026');

        verify(() => mockFirestoreService.streamCollection<Budget>(
              collectionPath: any(named: 'collectionPath'),
              builder: any<Budget Function(Map<String, dynamic>)>(named: 'builder'),
              filters: any(named: 'filters'),
            )).called(2);
      });

      test('should emit empty list safely when user session context is unauthenticated', () async {
        // Arrange
        final authSubject = BehaviorSubject<User?>.seeded(null);
        when(() => mockAuth.authStateChanges()).thenAnswer((_) => authSubject.stream);

        final streamExpectation = expectLater(
          repository.budgetsStream,
          emits(isEmpty),
        );

        // Act
        repository.updateMonthYear('05-2026');

        // Assert
        await streamExpectation;
        await authSubject.close();
      });
    });

    group('setBudget Mutator', () {
      final targetBudget = Budget(id: 'b1', userId: 'user_789', categoryId: 'cat_food', amount: 600.0, baseAmount: 600.0, currency: 'USD', monthYear: '05-2026');

      test('should route structural payload down to data tier service cleanly', () async {
        // Arrange
        when(() => mockFirestoreService.addDocument(
              collectionPath: any(named: 'collectionPath'),
              data: any(named: 'data'),
            )).thenAnswer((_) => Future.value());

        // Act
        await repository.setBudget(targetBudget);

        // Assert
        verify(() => mockFirestoreService.addDocument(
              collectionPath: any(named: 'collectionPath'),
              data: any(named: 'data'),
            )).called(1);
      });

      test('should reject modification execution and throw if state uid is unauthenticated', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(() => repository.setBudget(targetBudget), throwsException);
        verifyNever(() => mockFirestoreService.addDocument(
              collectionPath: any(named: 'collectionPath'),
              data: any(named: 'data'),
            ));
      });
    });
  });
}