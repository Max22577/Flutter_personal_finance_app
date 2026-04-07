import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/core/services/savings_service.dart'; 
import 'package:personal_fin/models/savings.dart';
import 'package:rxdart/rxdart.dart';

class MockFirestoreService extends Mock implements FirestoreService {}
class MockSavingsService extends Mock implements SavingsService {}

// Dummy class just for Mocktail fallback registration if needed
class FakeSavingsGoal extends Fake implements SavingsGoal {}

void main() {
  late SavingsRepository repository;
  late MockFirestoreService mockFirestore;
  late MockSavingsService mockSavingsService;
  late BehaviorSubject<List<SavingsGoal>> firestoreStreamSubject;

  setUpAll(() {
    // Register fallbacks if Mocktail complains about complex objects in verify
    registerFallbackValue(FakeSavingsGoal());
  });

  setUp(() {
    mockFirestore = MockFirestoreService();
    mockSavingsService = MockSavingsService();
    firestoreStreamSubject = BehaviorSubject<List<SavingsGoal>>();

    // Stub the stream immediately because _init() is called in the constructor!
    when(() => mockFirestore.streamSavingsGoals())
        .thenAnswer((_) => firestoreStreamSubject.stream);

    repository = SavingsRepository(
      firestore: mockFirestore,
      savingsService: mockSavingsService,
    );
  });

  tearDown(() {
    firestoreStreamSubject.close();
    repository.dispose();
  });

  group('Stream Updates -', () {
    test('goalsStream pipes data correctly from Firestore', () async {
      // ARRANGE
      final dummyGoals = [
        SavingsGoal(id: 'g1', name: 'New Car', targetAmount: 10000, currentAmount: 2000, deadline: DateTime(2026, 12, 31)),
      ];

      // ACT
      firestoreStreamSubject.add(dummyGoals);
      await Future.delayed(Duration.zero);

      // ASSERT
      final result = await repository.goalsStream.first;
      expect(result, dummyGoals);
      expect(result.first.name, 'New Car');
      verify(() => mockFirestore.streamSavingsGoals()).called(1);
    });
  });

  group('CRUD Operations -', () {
    final testGoal = SavingsGoal(id: 'g1', name: 'Vacation', targetAmount: 2000, currentAmount: 500, deadline: DateTime(2025, 6, 30));

    test('addGoal delegates correctly to Firestore', () async {
      // ARRANGE
      when(() => mockFirestore.addSavingsGoal(any()))
          .thenAnswer((_) async => Future.value());

      // ACT
      await repository.addGoal(testGoal);

      // ASSERT
      verify(() => mockFirestore.addSavingsGoal(testGoal)).called(1);
    });

    test('updateGoal delegates correctly to Firestore', () async {
      // ARRANGE
      when(() => mockFirestore.updateSavingsGoal(any()))
          .thenAnswer((_) async => Future.value());

      // ACT
      await repository.updateGoal(testGoal);

      // ASSERT
      verify(() => mockFirestore.updateSavingsGoal(testGoal)).called(1);
    });

    test('deleteGoal delegates correctly to Firestore', () async {
      // ARRANGE
      const goalId = 'g1';
      when(() => mockFirestore.deleteSavingsGoal(goalId))
          .thenAnswer((_) async => Future.value());

      // ACT
      await repository.deleteGoal(goalId);

      // ASSERT
      verify(() => mockFirestore.deleteSavingsGoal(goalId)).called(1);
    });
  });

  group('addToGoal -', () {
    const goalId = 'g1';
    const amount = 50.0;
    const defaultNote = 'Saved a bit extra!';

    setUp(() {
      // Stub the savings service to always complete successfully
      when(() => mockSavingsService.addToSavingsGoal(
            goalId: any(named: 'goalId'),
            amount: any(named: 'amount'),
            transactionNote: any(named: 'transactionNote'),
          )).thenAnswer((_) async => Future.value());
    });

    test('uses custom note when note is not empty', () async {
      // ACT
      final result = await repository.addToGoal(
        goalId: goalId,
        amount: amount,
        note: 'Bicycle fund update',
        defaultNote: defaultNote,
      );

      // ASSERT
      expect(result, true);
      verify(() => mockSavingsService.addToSavingsGoal(
            goalId: goalId,
            amount: amount,
            transactionNote: 'Bicycle fund update',
          )).called(1);
    });

    test('falls back to defaultNote when provided note is empty', () async {
      // ACT
      final result = await repository.addToGoal(
        goalId: goalId,
        amount: amount,
        note: '', // EMPTY!
        defaultNote: defaultNote,
      );

      // ASSERT
      expect(result, true);
      verify(() => mockSavingsService.addToSavingsGoal(
            goalId: goalId,
            amount: amount,
            transactionNote: defaultNote, // Should have fallen back!
          )).called(1);
    });
  });
}