import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/savings/view_models/add_to_savings_view_model.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

void main() {
  late AddToSavingsViewModel viewModel;
  late MockSavingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSavingsRepository();
    viewModel = AddToSavingsViewModel(mockRepo);
  });

  test('addToGoal returns false for non-positive amounts', () async {
    // ARRANGE
    const goalId = 'goal_123';
    const defaultNote = 'Default Note';

    // ACT
    final resultZero = await viewModel.addToGoal(
      goalId: goalId,
      amount: 0,
      note: 'Test Note',
      defaultNote: defaultNote,
    );

    final resultNegative = await viewModel.addToGoal(
      goalId: goalId,
      amount: -50,
      note: 'Test Note',
      defaultNote: defaultNote,
    );

    // ASSERT
    expect(resultZero, false, reason: 'Should return false for zero amount');
    expect(resultNegative, false, reason: 'Should return false for negative amount');
    
    // Verify that the repository method was never called since validation should fail first.
    verifyNever(() => mockRepo.addToGoal(
      goalId: any(named: 'goalId'),
      amount: any(named: 'amount'),
      note: any(named: 'note'),
      defaultNote: any(named: 'defaultNote'),
    ));
  });

  test('addToGoal calls repository method with correct parameters', () async {
    // ARRANGE
    const goalId = 'goal_123';
    const amount = 100.0;
    const note = 'Test Note';
    const defaultNote = 'Default Note';

    when(() => mockRepo.addToGoal(
      goalId: any(named: 'goalId'),
      amount: any(named: 'amount'),
      note: any(named: 'note'),
      defaultNote: any(named: 'defaultNote'),
    )).thenAnswer((_) async { return true; });

    // ACT
    final result = await viewModel.addToGoal(
      goalId: goalId,
      amount: amount,
      note: note,
      defaultNote: defaultNote,
    );

    // ASSERT
    expect(result, true, reason: 'Should return true for valid input');
    
    verify(() => mockRepo.addToGoal(
      goalId: goalId,
      amount: amount,
      note: note,
      defaultNote: defaultNote,
    )).called(1);
  });
}

