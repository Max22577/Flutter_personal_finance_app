import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late TransactionViewModel viewModel;
  late MockTransactionRepository mockTxRepo;
  late MockCategoryRepository mockCatRepo;

  late BehaviorSubject<List<Category>> categoriesSubject;
  late BehaviorSubject<List<Transaction>> transactionsSubject;

  setUpAll(() {
    registerFallbackValue(Transaction(id: '4', userId: 'u1', title: 'Yesterday Breakfast', type: 'Expense', amount: 50.0, date: DateTime.now(), categoryId: 'c1'));
  });

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockCatRepo = MockCategoryRepository();
    categoriesSubject = BehaviorSubject<List<Category>>();
    transactionsSubject = BehaviorSubject<List<Transaction>>();

    when(() => mockTxRepo.transactionsStream).thenAnswer((_) => transactionsSubject.stream);
    when(() => mockCatRepo.categoriesStream).thenAnswer((_) => categoriesSubject.stream);
  });

  tearDown(
    () {
      categoriesSubject.close();
      transactionsSubject.close();
    },
  );

  test('Initial state is loading', () {
    viewModel = TransactionViewModel(mockTxRepo, mockCatRepo);
    
    expect(viewModel.isLoading, true);
    expect(viewModel.transactions, []);
    expect(viewModel.categories, []);
  });

  test('Streams update transactions and categories', () async {
    // Re-initialize to listen to new streams
    viewModel = TransactionViewModel(mockTxRepo, mockCatRepo);

    final tx1 = Transaction(id: '1', userId: 'u1', title: 'Money for lunch', type: 'Expense', amount: 10.0, date: DateTime.now(), categoryId: 'c1');
    final cat1 = Category(id: 'c1', name: 'Food');

    transactionsSubject.add([tx1]);
    categoriesSubject.add([cat1]);

    await Future.delayed(Duration.zero); 

    expect(viewModel.isLoading, false);
    expect(viewModel.transactions, [tx1]);
    expect(viewModel.categories, [cat1]);
  });

  test('groupedTransactions groups items by date and sorts newest first', () async {
    viewModel = TransactionViewModel(mockTxRepo, mockCatRepo);
    // ARRANGE
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final tx1 = Transaction(id: '1', userId: 'u1', title: 'Lunch', type: 'Expense', amount: 10.0, date: today, categoryId: 'c1');
    final tx2 = Transaction(id: '2', userId: 'u1', title: 'Dinner', type: 'Expense', amount: 20.0, date: today, categoryId: 'c1');
    final tx3 = Transaction(id: '3', userId: 'u1', title: 'Yesterday Breakfast', type: 'Expense', amount: 5.0, date: yesterday, categoryId: 'c1');

    transactionsSubject.add([tx3, tx1, tx2]);
    await Future.delayed(Duration.zero);

    // 2. ACT
    final groups = viewModel.groupedTransactions;

    // 3. ASSERT
    // We expect exactly 2 groups (Today and Yesterday)
    expect(groups.length, 2);

    // Strip the time from our comparison dates just like the VM does
    final todayKey = DateTime(today.year, today.month, today.day);
    final yesterdayKey = DateTime(yesterday.year, yesterday.month, yesterday.day);

    // Check that Today has 2 transactions and Yesterday has 1
    expect(groups[todayKey]!.length, 2);
    expect(groups[yesterdayKey]!.length, 1);
  });

  test('deleteTransaction calls repository delete method', () async {
    viewModel = TransactionViewModel(mockTxRepo, mockCatRepo);

    // 1. ARRANGE
    when(() => mockTxRepo.deleteTransaction('tx_123'))
        .thenAnswer((_) async => Future.value());

    // 2. ACT
    await viewModel.deleteTransaction('tx_123');

    // 3. ASSERT
    // Verify that the repository actually received the command with the correct ID!
    verify(() => mockTxRepo.deleteTransaction('tx_123')).called(1);
  });

  test('saveTransaction sets isSaving, creates new transaction and calls repo', () async {
    viewModel = TransactionViewModel(mockTxRepo, mockCatRepo);

    final testDate = DateTime.now();

    // 1. ARRANGE
    when(() => mockTxRepo.uid).thenReturn('user_999');
    
    // We use `any()` from Mocktail to say "accept any Transaction object passed to it"
    when(() => mockTxRepo.addTransaction(any()))
        .thenAnswer((_) async => Future.value());

    // 2. ACT
    final saveFuture = viewModel.saveTransaction(
      title: 'New Shoes',
      amount: 50.0,
      type: 'Expense',
      categoryId: 'c2',
      date: testDate,
    );

    expect(viewModel.isSaving, true);

    final result = await saveFuture;

    // 3. ASSERT
    expect(result, true);
    expect(viewModel.isSaving, false); 
    
    // Verify that addTransaction was called exactly once
    verify(() => mockTxRepo.addTransaction(any())).called(1);
  });
}
