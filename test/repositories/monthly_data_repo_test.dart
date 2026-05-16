import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/network/query_options.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_auth/firebase_auth.dart';


// Mocks
class MockIFirestoreService extends Mock implements IFirestoreService {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MonthlyDataRepository repository;
  late MockIFirestoreService mockFirestoreService;
  late MockCategoryRepository mockCategoryRepository;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  const String testUid = 'user_123';

  setUpAll(() {
    // Register mocktail wildcards for custom collection filtering types
    registerFallbackValue(FieldFilter('test', FilterOperator.isEqualTo, 'test'));
    registerFallbackValue(OrderByOption('test'));
  });

  setUp(() {
    mockFirestoreService = MockIFirestoreService();
    mockCategoryRepository = MockCategoryRepository();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Default configuration for a logged-in user context
    when(() => mockUser.uid).thenReturn(testUid);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

    repository = MonthlyDataRepository(
      mockCategoryRepository,
      service: mockFirestoreService,
      auth: mockAuth,
    );
  });
  
  group('MonthlyDataRepository Tests', () {
    final testMonth = DateTime(2026, 5); // May 2026

    final sampleTransactions = [
      Transaction(type: 'Income', userId: testUid, title: 'Freelance Design', amount: 5000.0, baseAmount: 5000.0, currency: 'USD', categoryId: 'inc_1', date: DateTime(2026, 5, 15)),
      Transaction(type: 'Expense', userId: testUid, title: 'Grocery Shopping', amount: 150.0, baseAmount: 150.0, currency: 'USD', categoryId: 'cat_food', date: DateTime(2026, 5, 15)),
      Transaction(type: 'Expense', userId: testUid, title: 'Dinner Out', amount: 50.0, baseAmount: 50.0, currency: 'USD', categoryId: 'cat_food', date: DateTime(2026, 5, 15)),
      Transaction(type: 'Expense', userId: testUid, title: 'Rent Payment', amount: 100.0, baseAmount: 100.0, currency: 'USD', categoryId: 'cat_rent', date: DateTime(2026, 5, 15)),
    ];

    setUp(() {
      // Mock category lookups safely synchronously
      when(() => mockCategoryRepository.getNameByIdSync('cat_food')).thenReturn('Food');
      when(() => mockCategoryRepository.getNameByIdSync('cat_rent')).thenReturn('Rent');
    });

    group('streamMonthlyData', () {
      test('should map transactions to correctly computed MonthlyData calculations', () async {
        // Arrange
        when(() => mockFirestoreService.streamCollection<Transaction>(
              collectionPath: any(named: 'collectionPath'),
              builder: any<Transaction Function(Map<String, dynamic>)>(named: 'builder'),
              filters: any(named: 'filters'),
              orderBy: any(named: 'orderBy'),
            )).thenAnswer((_) => Stream.value(sampleTransactions));

        // Act & Assert
        expect(
          repository.streamMonthlyData(testMonth),
          emitsThrough(isA<MonthlyData>().having((d) => d.income, 'income', 5000.0)
                                       .having((d) => d.expenses, 'expenses', 300.0) // 150 + 50 + 100
                                       .having((d) => d.transactionCount, 'count', 4)
                                       .having((d) => d.categoryBreakdown, 'breakdown', {
                                         'Food': 200.0,
                                         'Rent': 100.0,
                                       })),
        );
      });

      test('should return empty MonthlyData stream if user is logged out', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          repository.streamMonthlyData(testMonth),
          emits(isA<MonthlyData>().having((d) => d.transactionCount, 'count', 0)),
        );
      });
    });

    group('getMonthlyData (Future)', () {
      test('should execute successfully and return parsed calculations', () async {
        // Arrange
        // (Ensuring your IFirestoreService contract covers future fetches)
        when(() => mockFirestoreService.getCollection<Transaction>(
              collectionPath: any(named: 'collectionPath'),
              builder: any<Transaction Function(Map<String, dynamic>)>(named: 'builder'),
              filters: any(named: 'filters'),
              orderBy: any(named: 'orderBy'),
            )).thenAnswer((_) => Future.value(sampleTransactions));

        // Act
        final result = await repository.getMonthlyData(testMonth);

        // Assert
        expect(result.income, 5000.0);
        expect(result.expenses, 300.0);
        expect(result.categoryBreakdown['Food'], 200.0);
      });

      test('should throw Exception when current user context is missing', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(() => repository.getMonthlyData(testMonth), throwsException);
      });
    });

    group('comparisonStream (Reactive RxDart Combinations)', () {
      test('should emit default empty initial seed immediately and react to user login', () async {
        // Arrange
        final authSubject = BehaviorSubject<User?>.seeded(null);
        when(() => mockAuth.authStateChanges()).thenAnswer((_) => authSubject.stream);

        // Setup the sub-calls triggered internally by streamMonthlyData inside switchMap
        when(() => mockFirestoreService.streamCollection<Transaction>(
              collectionPath: any(named: 'collectionPath'),
              builder: any<Transaction Function(Map<String, dynamic>)>(named: 'builder'),
              filters: any(named: 'filters'),
              orderBy: any(named: 'orderBy'),
            )).thenAnswer((_) => Stream.value(sampleTransactions));

        final streamToTest = repository.comparisonStream;

        // Act & Assert
        // Expectation 1: Unauthenticated stream emits explicit empty map layout
        expect(
          await streamToTest.first,
          {
            'current': isA<MonthlyData>().having((d) => d.transactionCount, 'count', 0),
            'previous': isA<MonthlyData>().having((d) => d.transactionCount, 'count', 0),
          },
        );

        // Transition State: Log the user in
        authSubject.add(mockUser);

        // Expectation 2: Skips initial emission, listening for updated breakdown evaluation
        expect(
          streamToTest.skip(1),
          emits(containsPair('current', isA<MonthlyData>().having((d) => d.income, 'income', 5000.0))),
        );

        await authSubject.close();
      });
    });
  });
}