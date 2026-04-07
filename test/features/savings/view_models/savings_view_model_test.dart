import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/savings/view_models/savings_view_model.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:rxdart/rxdart.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

void main() {
  late SavingsViewModel viewModel;
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

  test('Initial state is loading', () {
    viewModel = SavingsViewModel(mockRepo);
    
    expect(viewModel.isLoading, true);
    expect(viewModel.goals, []);
    expect(viewModel.errorMessage, null);
  });

  test('Stream updates goals and loading state', () async {
    viewModel = SavingsViewModel(mockRepo);

    final goal1 = SavingsGoal(id: 'g1', name: 'New Phone', targetAmount: 1000.0, currentAmount: 200.0, deadline: DateTime.now().add(Duration(days: 30)));
    
    goalsSubject.add([goal1]);

    await Future.delayed(Duration.zero);

    expect(viewModel.isLoading, false);
    expect(viewModel.goals, [goal1]);
    expect(viewModel.errorMessage, null);
  });

  test('Stream error updates errorMessage and loading state', () async {
    viewModel = SavingsViewModel(mockRepo);

    goalsSubject.addError(Exception('Failed to load goals'));

    await Future.delayed(Duration.zero);

    expect(viewModel.isLoading, false);
    expect(viewModel.goals, []);
    expect(viewModel.errorMessage, 'Exception: Failed to load goals');
  });

  test('Calculates totals and progress correctly under normal conditions', () async {
    viewModel = SavingsViewModel(mockRepo);

    // 1. ARRANGE
    goalsSubject.add([
      SavingsGoal(id: '1', name: 'New Phone', targetAmount: 100.0, currentAmount: 50.0, deadline: DateTime.now().add(Duration(days: 30))),
      SavingsGoal(id: '2', name: 'Vacation', targetAmount: 200.0, currentAmount: 100.0, deadline: DateTime.now().add(Duration(days: 60))),
    ]);
    
    await Future.delayed(Duration.zero);

    // 2. ACT & 3. ASSERT
    expect(viewModel.totalTarget, 300.0);
    
    expect(viewModel.totalSaved, 150.0);
    
    // Test overallProgress (150 / 300 = 0.5)
    expect(viewModel.overallProgress, 0.5);
  });

  test('overallProgress returns 0 when totalTarget is zero (division by zero guard)', () async {
    viewModel = SavingsViewModel(mockRepo);

    // 1. ARRANGE
    // No goals added, or goals with 0 target
    goalsSubject.add([
      SavingsGoal(id: '1', name: 'New Phone', targetAmount: 0.0, currentAmount: 0.0, deadline: DateTime.now().add(Duration(days: 30))),
    ]);
    await Future.delayed(Duration.zero);

    // 2. ACT & 3. ASSERT
    expect(viewModel.totalTarget, 0.0);
    expect(viewModel.overallProgress, 0.0); 
  });

  test('overallProgress is clamped to 1.0 even if user over-saves', () async {
    viewModel = SavingsViewModel(mockRepo);

    // 1. ARRANGE
    goalsSubject.add([
      SavingsGoal(id: '1', name: 'New Phone', targetAmount: 100.0, currentAmount: 150.0, deadline: DateTime.now().add(Duration(days: 30))),
    ]);
    await Future.delayed(Duration.zero);

    // 2. ACT & 3. ASSERT
    expect(viewModel.totalSaved, 150.0);
    // Even though 150 / 100 = 1.5, clamp(0.0, 1.0) should force it to 1.0
    expect(viewModel.overallProgress, 1.0);
  });
}