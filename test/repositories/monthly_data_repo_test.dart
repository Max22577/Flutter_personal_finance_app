import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:firebase_auth/firebase_auth.dart';


// Mocks
class MockIFirestoreService extends Mock implements IFirestoreService {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockExchangeService extends Mock implements ExchangeRateService {}
class MockCurrencyProvider extends Mock implements CurrencyProvider {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MonthlyDataRepository repository;
  late MockIFirestoreService mockFirestoreService;
  late MockCategoryRepository mockCategoryRepository;
  late MockExchangeService mockExchangeService;
  late MockCurrencyProvider mockCurrencyProvider;
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
    mockExchangeService = MockExchangeService();
    mockCurrencyProvider = MockCurrencyProvider();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Default configuration for a logged-in user context
    when(() => mockUser.uid).thenReturn(testUid);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
    when(() => mockCurrencyProvider.currentCurrency).thenReturn('KSH');
  
    // Default stub: simple conversion logic (if KSH, multiply by 100 for testing)
    when(() => mockExchangeService.fromBase(any(), 'KSH')).thenAnswer((inv) {
      return (inv.positionalArguments[0] as double) * 100;
    });
    // Default stub: if USD, return as is
    when(() => mockExchangeService.fromBase(any(), 'USD')).thenAnswer((inv) {
      return inv.positionalArguments[0] as double;
    });

    repository = MonthlyDataRepository(
      mockCategoryRepository,
      mockExchangeService,
      mockCurrencyProvider,
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
          repository.streamMonthlyData(testMonth, 'KSH'),
          emitsThrough(isA<MonthlyData>()
              .having((d) => d.income, 'income converted', 500000.0)
              .having((d) => d.expenses, 'expenses converted', 30000.0)
              .having((d) => d.categoryBreakdown['Food'], 'breakdown converted', 20000.0)),
        );
      });

      test('should return empty MonthlyData stream if user is logged out', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          repository.streamMonthlyData(testMonth, 'KSH'),
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
        final result = await repository.getMonthlyData(testMonth, 'KSH');

        // Assert
        expect(result.income, 500000.0);
        expect(result.expenses, 30000.0);
        expect(result.categoryBreakdown['Food'], 20000.0);
      });

      test('should throw Exception when current user context is missing', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(() => repository.getMonthlyData(testMonth, 'KSH'), throwsException);
      });
    });

    group('comparisonStream (Reactive RxDart Combinations)', () {
      test('should emit default empty initial seed immediately and react to user login', () async {
        // Arrange
        when(() => mockCurrencyProvider.currentCurrency).thenReturn('KSH');

        // Setup the sub-calls triggered internally by streamMonthlyData inside switchMap
        when(() => mockFirestoreService.streamCollection<Transaction>(
          collectionPath: any(named: 'collectionPath'),
          builder: any<Transaction Function(Map<String, dynamic>)>(named: 'builder'),
          filters: any(named: 'filters'),
          orderBy: any(named: 'orderBy'),
        )).thenAnswer((_) => Stream.value(sampleTransactions));

        final data = await repository.comparisonStream.skip(1).first;

        // Act & Assert
        expect(data['current']!.income, 500000.0);
      });
    });
  });
}