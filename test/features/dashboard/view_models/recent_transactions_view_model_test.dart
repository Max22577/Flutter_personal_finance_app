import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/features/dashboard/view_models/recent_transactions_view_model.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';


class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late RecentTransactionsViewModel viewModel;
  late MockTransactionRepository mockTxRepo;
  late MockCategoryRepository mockCatRepo;

  final date1 = DateTime(2026, 5, 15);
  final date2 = DateTime(2026, 5, 16);
  final date3 = DateTime(2026, 5, 17); // Most recent

  final sampleTransactions = [
    Transaction(id: 't1', userId: 'u1', title: 'Oldest', amount: 10.0, currency: 'USD', baseAmount: 10.0, type: 'Expense', categoryId: 'cat_food', date: date1),
    Transaction(id: 't2', userId: 'u1', title: 'Middle', amount: 20.0, currency: 'USD', baseAmount: 20.0, type: 'Expense', categoryId: 'cat_rent', date: date2),
    Transaction(id: 't3', userId: 'u1', title: 'Newest', amount: 30.0, currency: 'USD', baseAmount: 30.0, type: 'Expense', categoryId: 'cat_food', date: date3),
    Transaction(id: 't4', userId: 'u1', title: 'Extra 1', amount: 40.0, currency: 'USD', baseAmount: 40.0, type: 'Expense', categoryId: 'cat_misc', date: date1),
    Transaction(id: 't5', userId: 'u1', title: 'Extra 2', amount: 50.0, currency: 'USD', baseAmount: 50.0, type: 'Expense', categoryId: 'cat_misc', date: date1),
    Transaction(id: 't6', userId: 'u1', title: 'Extra 3', amount: 60.0, currency: 'USD', baseAmount: 60.0, type: 'Expense', categoryId: 'cat_misc', date: date1),
  ];

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockCatRepo = MockCategoryRepository();

    // Default category stubs
    when(() => mockCatRepo.getNameByIdSync('cat_food')).thenReturn('Food & Dining');
    when(() => mockCatRepo.getNameByIdSync('cat_rent')).thenReturn('Housing');
    when(() => mockCatRepo.getNameByIdSync('cat_misc')).thenReturn('Miscellaneous');
  });

  group('RecentTransactionsViewModel Tests', () {
    test('should sort transactions descending by date and limit results to maxItems', () async {
      // Arrange
      final streamController = BehaviorSubject<List<Transaction>>.seeded(sampleTransactions);
      when(() => mockTxRepo.transactionsStream).thenAnswer((_) => streamController.stream);

      // Act
      viewModel = RecentTransactionsViewModel(
        repo: mockTxRepo,
        catRepo: mockCatRepo,
        maxItems: 3, // Custom limit to strictly verify sizing boundaries
      );

      // Wait for stream event loop processing step
      await Future.delayed(Duration.zero);

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      
      // Sizing check
      expect(viewModel.recentTransactions.length, 3);
      
      // Order checking (Descending: t3, then t2, then any date1 transaction)
      expect(viewModel.recentTransactions[0].id, 't3'); // May 17
      expect(viewModel.recentTransactions[1].id, 't2'); // May 16

      await streamController.close();
    });

    test('should resolve category names through category lookup map correctly', () async {
      // Arrange
      final streamController = BehaviorSubject<List<Transaction>>.seeded(sampleTransactions);
      when(() => mockTxRepo.transactionsStream).thenAnswer((_) => streamController.stream);

      // Act
      viewModel = RecentTransactionsViewModel(repo: mockTxRepo, catRepo: mockCatRepo);
      await Future.delayed(Duration.zero);

      // Assert
      expect(viewModel.getCategoryName('cat_food'), 'Food & Dining');
      expect(viewModel.getCategoryName('cat_rent'), 'Housing');
      // A non-existent or unmapped key fallback value check
      expect(viewModel.getCategoryName('unknown_id'), 'Loading...');

      // Ensure repository was hit exactly for the IDs discovered in recent list
      verify(() => mockCatRepo.getNameByIdSync('cat_food')).called(1);

      await streamController.close();
    });

    test('should capture internal stream errors and assign correct visual error message flags', () async {
      // Arrange
      when(() => mockTxRepo.transactionsStream)
          .thenAnswer((_) => Stream<List<Transaction>>.error('Connection Dropped'));

      // Act
      viewModel = RecentTransactionsViewModel(repo: mockTxRepo, catRepo: mockCatRepo);
      await Future.delayed(Duration.zero);

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.recentTransactions, isEmpty);
      expect(viewModel.errorMessage, 'Connection to transactions lost');
    });

    test('should capture processing conversion errors safely if data mapping explodes', () async {
      // Arrange - Force category repository lookup calculation to crash
      when(() => mockCatRepo.getNameByIdSync(any())).thenThrow(UnimplementedError('DB Lock'));
      
      final streamController = BehaviorSubject<List<Transaction>>.seeded(sampleTransactions);
      when(() => mockTxRepo.transactionsStream).thenAnswer((_) => streamController.stream);

      // Act
      viewModel = RecentTransactionsViewModel(repo: mockTxRepo, catRepo: mockCatRepo);
      await Future.delayed(Duration.zero);

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, 'Failed to process transactions');

      await streamController.close();
    });

    test('retry should cleanly restart stream pipeline listener references', () async {
      // Arrange
      final streamController = BehaviorSubject<List<Transaction>>.seeded([]);
      when(() => mockTxRepo.transactionsStream).thenAnswer((_) => streamController.stream);

      viewModel = RecentTransactionsViewModel(repo: mockTxRepo, catRepo: mockCatRepo);
      await Future.delayed(Duration.zero);

      // Artificially pollute layout states to verify structural refresh cleaning rules
      viewModel.retry();

      // Assert it re-toggles initial states instantly on invocation kick
      expect(viewModel.isLoading, true);
      expect(viewModel.errorMessage, null);

      await streamController.close();
    });

    test('dispose should completely clear listener hooks to stop subscription leak paths', () async {
      // Arrange
      final streamController = BehaviorSubject<List<Transaction>>();
      when(() => mockTxRepo.transactionsStream).thenAnswer((_) => streamController.stream);

      viewModel = RecentTransactionsViewModel(repo: mockTxRepo, catRepo: mockCatRepo);

      // Act & Assert
      expect(streamController.hasListener, true);
      viewModel.dispose();
      expect(streamController.hasListener, false);

      await streamController.close();
    });
  });
}