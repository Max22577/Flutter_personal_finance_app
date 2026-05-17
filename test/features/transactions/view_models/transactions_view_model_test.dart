import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';


class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late TransactionViewModel viewModel;
  late MockTransactionRepository mockTxRepo;
  late MockCategoryRepository mockCatRepo;
  late MockExchangeRateService mockExchangeService;

  setUpAll(() {
    registerFallbackValue(Transaction(
      id: '',
      userId: '',
      title: 'Fallback',
      amount: 0.0,
      currency: 'USD',
      baseAmount: 0.0,
      type: 'Expense',
      categoryId: '',
      date: DateTime.now(),
    ));
  });

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockCatRepo = MockCategoryRepository();
    mockExchangeService = MockExchangeRateService();

    // Default setups
    when(() => mockTxRepo.currentUid).thenReturn('user_abc123');
    when(() => mockExchangeService.toBase(any(), any())).thenAnswer((inv) => inv.positionalArguments[0] as double);

    viewModel = TransactionViewModel(
      mockTxRepo,
      mockCatRepo,
      exchangeService: mockExchangeService,
    );
  });

  group('TransactionViewModel Tests', () {
    final dateDay1 = DateTime(2026, 5, 17, 10, 30);
    final dateDay1Later = DateTime(2026, 5, 17, 14, 0);
    final dateDay2 = DateTime(2026, 5, 18, 9, 15);

    final sampleTransactions = [
      Transaction(id: 't1', userId: 'user_abc123', title: 'Coffee', amount: 5.0, currency: 'USD', baseAmount: 5.0, type: 'Expense', categoryId: 'cat_food', date: dateDay1),
      Transaction(id: 't2', userId: 'user_abc123', title: 'Lunch', amount: 15.0, currency: 'USD', baseAmount: 15.0, type: 'Expense', categoryId: 'cat_food', date: dateDay1Later),
      Transaction(id: 't3', userId: 'user_abc123', title: 'Salary', amount: 3000.0, currency: 'USD', baseAmount: 3000.0, type: 'Income', categoryId: 'cat_salary', date: dateDay2),
    ];

    group('Data Streams & Feeds Delegation', () {
      test('transactions should forward from underlying repository streams safely', () {
        when(() => mockTxRepo.transactionsStream).thenAnswer((_) => Stream.value(sampleTransactions));
        expect(viewModel.transactions, emits(sampleTransactions));
      });

      test('categoriesStream should forward clean collection options from categories data layer', () {
        final mockCategories = [Category(id: 'cat_food', name: 'Food')];
        when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => Stream.value(mockCategories));
        expect(viewModel.categoriesStream, emits(mockCategories));
      });

      test('categories synchronous getter should pull current state from cache reference list', () {
        final mockCache = [Category(id: 'cat_rent', name: 'Rent')];
        when(() => mockCatRepo.categories).thenReturn(mockCache);
        expect(viewModel.categories, mockCache);
      });
    });

    group('groupTransactions Transformation Utility', () {
      test('should strip hours/minutes/seconds and group transactions by exact calendar date', () {
        // Act
        final grouped = viewModel.groupTransactions(sampleTransactions);

        // Assert
        // Expecting two keys: May 17, 2026 and May 18, 2026
        expect(grouped.keys.length, 2);
        
        final normalizationKey1 = DateTime(2026, 5, 17);
        final normalizationKey2 = DateTime(2026, 5, 18);

        expect(grouped[normalizationKey1]?.length, 2); // Coffee and Lunch grouped together
        expect(grouped[normalizationKey2]?.length, 1); // Salary grouped alone
        expect(grouped[normalizationKey1]?.first.title, 'Coffee');
      });
    });

    group('saveTransaction Management Flow', () {
      test('should create a fresh transaction record using repository addTransaction method when no existing instance is specified', () async {
        // Arrange
        when(() => mockTxRepo.addTransaction(any())).thenAnswer((_) => Future.value());
        
        int listenerNotificationCounter = 0;
        viewModel.addListener(() => listenerNotificationCounter++);

        // Act
        final result = await viewModel.saveTransaction(
          title: '  Groceries ', // Verifying the internal .trim() is handled
          amount: 45.0,
          currency: 'USD',
          type: 'Expense',
          categoryId: 'cat_food',
          date: dateDay1,
        );

        // Assert
        expect(result, true);
        expect(viewModel.isSaving, false);
        expect(listenerNotificationCounter, 2); // 1 for setting true, 1 for turning false in finally block
        
        verify(() => mockTxRepo.addTransaction(any(that: isA<Transaction>()
          .having((t) => t.id, 'empty id for new', '')
          .having((t) => t.title, 'trimmed text title', 'Groceries')
          .having((t) => t.baseAmount, 'exchange calculation logic check', 45.0)
        ))).called(1);
        verifyNever(() => mockTxRepo.updateTransaction(any()));
      });

      test('should target existing identifiers and call updateTransaction when handling an adjustment modification workflow', () async {
        // Arrange
        final oldTx = sampleTransactions.first;
        when(() => mockTxRepo.updateTransaction(any())).thenAnswer((_) => Future.value());

        // Act
        final result = await viewModel.saveTransaction(
          title: 'Premium Coffee',
          amount: 6.0,
          currency: 'USD',
          type: 'Expense',
          categoryId: 'cat_food',
          date: dateDay1,
          existingTransaction: oldTx,
        );

        // Assert
        expect(result, true);
        verify(() => mockTxRepo.updateTransaction(any(that: isA<Transaction>()
          .having((t) => t.id, 'matches original target record identifier', 't1')
          .having((t) => t.title, 'updated title string text', 'Premium Coffee')
        ))).called(1);
        verifyNever(() => mockTxRepo.addTransaction(any()));
      });

      test('should gracefully capture and return false if repository exceptions occur during operation steps', () async {
        // Arrange
        when(() => mockTxRepo.addTransaction(any())).thenThrow(Exception('Firestore Outage Error'));

        // Act
        final result = await viewModel.saveTransaction(
          title: 'Failing Tx',
          amount: 1.0,
          currency: 'USD',
          type: 'Expense',
          categoryId: 'cat_misc',
          date: dateDay1,
        );

        // Assert
        expect(result, false);
        expect(viewModel.isSaving, false); // Confirms loading toggles back down inside finally blocks
      });
    });

    group('deleteTransaction Feature Block', () {
      test('should successfully delegate targeted id downward to transaction persistent tiers', () async {
        // Arrange
        when(() => mockTxRepo.deleteTransaction('t1')).thenAnswer((_) => Future.value());

        // Act
        await viewModel.deleteTransaction('t1');

        // Assert
        verify(() => mockTxRepo.deleteTransaction('t1')).called(1);
      });

      test('should intercept and gracefully catch data engine deletion exceptions natively without breaking UI loop structures', () async {
        // Arrange
        when(() => mockTxRepo.deleteTransaction('invalid_id')).thenThrow(Exception('Record not found'));

        // Act & Assert (Should execute cleanly without throwing up out of the view model boundary method)
        await expectLater(viewModel.deleteTransaction('invalid_id'), completes);
      });
    });
  });
}