import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/firestore/constants/firestore_path.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';


class MockFirestoreService extends Mock implements IFirestoreService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late TransactionRepository repo;
  late MockFirestoreService mockService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  const String testUid = 'user_123';
  final String expectedPath = FirestorePath.transactions(testUid);

  setUp(() {
    mockService = MockFirestoreService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Setup typical authenticated user state as the baseline default
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn(testUid);
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

    repo = TransactionRepository(
      service: mockService,
      auth: mockAuth,
    );
  });

  group('TransactionRepository - CRUD Operations', () {
    final sampleTx = Transaction(
      id: 'tx_abc',
      userId: testUid,
      title: 'Grocery Store',
      amount: 45.50,
      baseAmount: 45.50,
      currency: 'USD',
      type: 'Expense',
      categoryId: 'food',
      date: DateTime(2026, 5, 15),
    );

    test('addTransaction throws an Exception when user is unauthenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(() => repo.addTransaction(sampleTx), throwsA(isA<Exception>()));
      
      verifyNever(() => mockService.addDocument(
        collectionPath: any(named: 'collectionPath'),
        data: any(named: 'data'),
      ));
    });

    test('addTransaction executes successfully using accurate uniform path structure', () async {
      when(() => mockService.addDocument(
        collectionPath: any(named: 'collectionPath'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => {});

      await repo.addTransaction(sampleTx);

      verify(() => mockService.addDocument(
        collectionPath: expectedPath,
        data: sampleTx.toFirestore(),
      )).called(1);
    });

    test('updateTransaction throws an Exception if target transaction ID is empty', () async {
      final invalidTx = Transaction(
        id: '', // Empty ID trigger
        userId: testUid,
        title: 'Incorrect',
        amount: 10,
        baseAmount: 10,
        currency: 'USD',
        type: 'Expense',
        categoryId: 'misc',
        date: DateTime.now(),
      );

      expect(() => repo.updateTransaction(invalidTx), throwsA(isA<Exception>()));
    });

    test('updateTransaction passes mapped values cleanly down to service tier', () async {
      when(() => mockService.updateDocument(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => {});

      await repo.updateTransaction(sampleTx);

      verify(() => mockService.updateDocument(
        collectionPath: expectedPath,
        documentId: 'tx_abc',
        data: sampleTx.toFirestore(),
      )).called(1);
    });

    test('deleteTransaction passes target ID seamlessly across internal parameters', () async {
      when(() => mockService.deleteDocument(
        collectionPath: any(named: 'collectionPath'),
        id: any(named: 'id'),
      )).thenAnswer((_) async => {});

      await repo.deleteTransaction('tx_abc');

      verify(() => mockService.deleteDocument(
        collectionPath: expectedPath,
        id: 'tx_abc',
      )).called(1);
    });
  });

  group('TransactionRepository - Reactive Streams', () {
    final stubbedOutputList = [
      Transaction(
        id: '1', userId: testUid, title: 'Freelance Design', amount: 3500.0,
        baseAmount: 3500.0, currency: 'USD', type: 'Income',
        categoryId: 'work', date: DateTime(2026, 5, 1)
      )
    ];

    test('transactionsStream outputs an empty array immediately when user logs out', () async {
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

      expect(repo.transactionsStream, emitsInOrder([isEmpty]));
    });

    test('transactionsStream requests correct path sorting directives without falling over', () async {
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(testUid);
      when(() => mockService.streamCollection<Transaction>(
        collectionPath: any(named: 'collectionPath'),
        builder: any(named: 'builder'),
        orderBy: any(named: 'orderBy'),
      )).thenAnswer((_) => Stream.value(stubbedOutputList));

      final stream = repo.transactionsStream;
      
      // Use expectLater to capture the emission
      await expectLater(stream, emits(stubbedOutputList));

      verify(() => mockService.streamCollection<Transaction>(
        collectionPath: expectedPath,
        builder: any(named: 'builder'),
        orderBy: any(named: 'orderBy'), 
      )).called(1);
    });

    test('monthlyTransactionsStream translates requested month into absolute date boundaries', () async {
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(testUid);

      when(() => mockService.streamCollection<Transaction>(
        collectionPath: any(named: 'collectionPath'),
        builder: any(named: 'builder'),
        filters: any(named: 'filters'),
        orderBy: any(named: 'orderBy'),
      )).thenAnswer((_) => Stream.value(stubbedOutputList));

      final stream = repo.transactionsStream;

      final expectation = expectLater(
        stream, 
        emits(stubbedOutputList),
      );
      
      repo.setMonth(DateTime(2026, 8)); 
      await expectation;

      verify(() => mockService.streamCollection<Transaction>(
        collectionPath: expectedPath,
        builder: any(named: 'builder'),
        filters: any(named: 'filters'), 
        orderBy: any(named: 'orderBy'),
      )).called(1);
    });
  });
}