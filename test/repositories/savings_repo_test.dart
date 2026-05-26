import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/firestore/constants/firestore_path.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';


class MockFirestoreService extends Mock implements IFirestoreService {}
class MockTransactionRepo extends Mock implements TransactionRepository {}
class MockExchangeService extends Mock implements ExchangeRateService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late SavingsRepository repo;
  late MockFirestoreService mockService;
  late MockTransactionRepo mockTxRepo;
  late MockExchangeService mockExchange;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockService = MockFirestoreService();
    mockTxRepo = MockTransactionRepo();
    mockExchange = MockExchangeService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Default: User is logged in
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('user_123');

    repo = SavingsRepository(
      mockTxRepo,
      service: mockService,
      exchangeService: mockExchange,
      auth: mockAuth,
    );
    
    // Register fallback for custom types if using any() matchers
    registerFallbackValue(Transaction(userId: '', title: '', amount: 0, baseAmount: 0, currency: '', type: '', categoryId: '', date: DateTime.now()));
  });

  group('SavingsRepository - contributeToGoal', () {
    test('successfully calculates exchange rate and calls both repos', () async {
      // Arrange
      final expectedPath = FirestorePath.savingsGoals('user_123');
      const amount = 100.0;
      const baseAmount = 1.0; // 100 currency = 1 USD
      
      when(() => mockExchange.toBase(any(), any())).thenReturn(baseAmount);
      when(() => mockTxRepo.addTransaction(any())).thenAnswer((_) async => {});
      when(() => mockService.updateDocument(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => {});

      // Act
      await repo.contributeToGoal(
        goalId: 'goal_1',
        amount: amount,
        currency: 'EUR',
        note: 'Save for bike',
      );

      // Assert
      verify(() => mockExchange.toBase(amount, 'EUR')).called(1);
      verify(() => mockTxRepo.addTransaction(any())).called(1);
      verify(() => mockService.updateDocument(
        collectionPath: expectedPath,
        documentId: 'goal_1',
        data: any(named: 'data'),
      )).called(1);
    });
  });

  group('SavingsRepository - CRUD', () {
    test('deleteGoal calls service with correct path and ID', () async {
      final expectedPath = FirestorePath.savingsGoals('user_123');
      when(() => mockService.deleteDocument(
        collectionPath: any(named: 'collectionPath'),
        id: any(named: 'id'),
      )).thenAnswer((_) async => {});

      await repo.deleteGoal('target_id');

      verify(() => mockService.deleteDocument(
        collectionPath: expectedPath,
        id: 'target_id',
      )).called(1);
    });
  });
}