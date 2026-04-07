import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/features/savings/view_models/set_goal_view_model.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:rxdart/rxdart.dart';


class MockSavingsRepository extends Mock implements SavingsRepository {}

void main() {
  late SetGoalViewModel viewModel;
  late MockSavingsRepository mockRepo;
  late BehaviorSubject<List<SavingsGoal>> goalsSubject;

  setUp(() {
    mockRepo = MockSavingsRepository();
    goalsSubject = BehaviorSubject<List<SavingsGoal>>();

    when(() => mockRepo.goalsStream).thenAnswer((_) => goalsSubject.stream);
  });

  tearDown(() {
    goalsSubject.close();
  });

  test('Constructor sets default deadline to 30 days from now when creating a new goal', () {
    // 1. ARRANGE
    // existingGoal will be null by default)

    // 2. ACT
    viewModel = SetGoalViewModel(mockRepo);

    // 3. ASSERT
    // We expect the deadline to be roughly 30 days from now.
    final expectedDeadline = DateTime.now().add(const Duration(days: 30));
    
    // Because DateTime.now() moves by milliseconds while the test runs, 
    // we check if the difference between them is less than a second.
    final difference = viewModel.deadline.difference(expectedDeadline).inSeconds.abs();
    expect(difference < 1, true, reason: 'Deadline should be 30 days from now');
  });

  test('Constructor pre-fills data when an existing goal is passed', () {
    // 1. ARRANGE
    final dummyDeadline = DateTime.now().add(const Duration(days: 15));
    final testGoal = SavingsGoal(
      id: 'goal_123',
      name: 'New Car Fund',
      targetAmount: 5000.0,
      currentAmount: 100.0,
      deadline: dummyDeadline,
    );

    // 2. ACT
    viewModel = SetGoalViewModel(mockRepo, existingGoal: testGoal);

    // 3. ASSERT
    // Verify everything was mapped from the goal onto the ViewModel correctly!
    expect(viewModel.name, 'New Car Fund');
    expect(viewModel.targetAmount, 5000.0);
    expect(viewModel.deadline, dummyDeadline);
  });

  test('updateName updates the name state', () {
    viewModel = SetGoalViewModel(mockRepo);
    
    viewModel.updateName('Save for Laptop');
    
    expect(viewModel.name, 'Save for Laptop');
  });

  test('updateAmount parses valid double strings and defaults to 0.0 on invalid ones', () {
    viewModel = SetGoalViewModel(mockRepo);
    
    // Test valid string
    viewModel.updateAmount('250.50');
    expect(viewModel.targetAmount, 250.50);

    // Test invalid string - should default to 0.0 and not throw an error
    viewModel.updateAmount('not_a_number');
    expect(viewModel.targetAmount, 0.0);
  });

  test('isEditing returns true only when an existing goal is passed in', () {
    // Branch 1: No existing goal
    final vmNew = SetGoalViewModel(mockRepo);
    expect(vmNew.isEditing, false);

    // Branch 2: With existing goal
    final testGoal = SavingsGoal(id: '1', name: 'Test', targetAmount: 100, currentAmount: 0, deadline: DateTime.now());
    final vmEdit = SetGoalViewModel(mockRepo, existingGoal: testGoal);
    expect(vmEdit.isEditing, true);
  });
}