import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/core/services/savings_service.dart';
import 'package:personal_fin/models/transaction.dart';


class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockSavingsRepository extends Mock implements SavingsRepository {}
class MockIFirestoreService extends Mock implements IFirestoreService {}

void main() {
  late MockTransactionRepository mockTxRepo;
  late MockSavingsRepository mockSavingsRepo;
  late SavingsService savingsService;
  late MockIFirestoreService mockFirestoreService;

  setUpAll(() {
    registerFallbackValue(Transaction(
      userId: 'user_123',
      title: 'Test Transaction',
      amount: 100.0,
      baseAmount: 100.0,
      currency: 'USD',
      type: 'Expense',
      categoryId: 'cat_test',
      date: DateTime.now(),
    ));
  });

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockSavingsRepo = MockSavingsRepository();
    mockFirestoreService = MockIFirestoreService();
    
    savingsService = SavingsService(
      transactionRepo: mockTxRepo,
      savingsRepo: mockSavingsRepo,
      firestoreService: mockFirestoreService,
    );

    // Setup default mock behaviors
    when(() => mockSavingsRepo.currentUid).thenReturn('user_123');
    when(() => mockSavingsRepo.goalsCollectionPath).thenReturn('users/user_123/savings_goals');
  });

  group('SavingsService Tests', () {

    test('addToSavingsGoal successfully orchestrates transaction and update', () async {
      // Stubbing
      when(() => mockSavingsRepo.currentUid).thenReturn('user_123');
      when(() => mockSavingsRepo.goalsCollectionPath).thenReturn('test/path');
      
      when(() => mockTxRepo.addTransaction(any())).thenAnswer((_) async => {});
      
      when(() => mockFirestoreService.updateDocumentById(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => {});

      // Act
      await savingsService.addToSavingsGoal(
        goalId: 'goal_1',
        amount: 50.0,
        baseAmount: 50.0,
        currency: 'USD',
      );

      // Assert 
      verify(() => mockTxRepo.addTransaction(any())).called(1);
      verify(() => mockFirestoreService.updateDocumentById(
        collectionPath: 'test/path',
        documentId: 'goal_1',
        data: any(named: 'data'),
      )).called(1);
    });

    test('withdrawFromSavingsGoal handles UserID and matchers correctly', () async {
      when(() => mockSavingsRepo.currentUid).thenReturn('user_123');
      when(() => mockSavingsRepo.goalsCollectionPath).thenReturn('test/path');
      when(() => mockTxRepo.addTransaction(any())).thenAnswer((_) async => {});
      when(() => mockFirestoreService.updateDocumentById(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => {});

      await savingsService.withdrawFromSavingsGoal(
        goalId: 'goal_1',
        amount: 20.0,
        currency: 'USD',
      );

      verify(() => mockFirestoreService.updateDocumentById(
        collectionPath: any(named: 'collectionPath'),
        documentId: 'goal_1',
        data: any(named: 'data'),
      )).called(1);
    });
  });
}