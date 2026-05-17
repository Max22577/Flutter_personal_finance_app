import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/features/savings/view_models/set_goal_view_model.dart';
import 'package:personal_fin/models/savings.dart';


class MockSavingsRepository extends Mock implements SavingsRepository {}
class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late SetGoalViewModel viewModel;
  late MockSavingsRepository mockRepository;
  late MockExchangeRateService mockExchangeService;

  setUpAll(() {
    registerFallbackValue(SavingsGoal(
      id: '',
      name: 'Fallback',
      targetAmount: 0.0,
      currentAmount: 0.0,
      deadline: DateTime.now(),
      currency: 'USD',
      targetBaseAmount: 0.0,
      currentBaseAmount: 0.0,
    ));
  });

  setUp(() {
    mockRepository = MockSavingsRepository();
    mockExchangeService = MockExchangeRateService();
    when(() => mockExchangeService.toBase(any(), any())).thenAnswer((invocation) {
      final double target = invocation.positionalArguments[0] as double;
      return target; // Return 1:1 ratio or a fixed calculated test stub value
    });
  });

  group('SetGoalViewModel Tests', () {
    final testDeadline = DateTime(2026, 12, 31);

    group('Initialization State', () {
      test('should init with default blank data when no existing goal is passed', () {
        viewModel = SetGoalViewModel(mockRepository, exchangeService: mockExchangeService);

        expect(viewModel.name, '');
        expect(viewModel.targetAmount, 0.0);
        expect(viewModel.isEditing, false);
        expect(viewModel.deadline.isAfter(DateTime.now()), true);
      });

      test('should populate properties correctly when an existing goal is injected', () {
        final existing = SavingsGoal(
          id: 'goal_123',
          name: 'Buy a Tesla',
          targetAmount: 50000.0,
          currentAmount: 5000.0,
          deadline: testDeadline,
          currency: 'USD',
          targetBaseAmount: 50000.0,
          currentBaseAmount: 5000.0,
        );

        viewModel = SetGoalViewModel(mockRepository, existingGoal: existing, exchangeService: mockExchangeService);

        expect(viewModel.name, 'Buy a Tesla');
        expect(viewModel.targetAmount, 50000.0);
        expect(viewModel.isEditing, true);
        expect(viewModel.deadline, testDeadline);
      });
    });

    group('State Adjustments & UI Listeners', () {
      test('updateName should update value and notify UI listeners', () {
        viewModel = SetGoalViewModel(mockRepository, exchangeService: mockExchangeService);
        int listenerCount = 0;
        viewModel.addListener(() => listenerCount++);

        viewModel.updateName('New Laptop');

        expect(viewModel.name, 'New Laptop');
        expect(listenerCount, 1);
      });

      test('updateAmount should parse text inputs safely into doubles', () {
        viewModel = SetGoalViewModel(mockRepository, exchangeService: mockExchangeService);
        
        viewModel.updateAmount('250.50');
        expect(viewModel.targetAmount, 250.50);

        // Should fall back to 0.0 on malformed input strings
        viewModel.updateAmount('invalid_number');
        expect(viewModel.targetAmount, 0.0);
      });
    });

    group('Save / Update Actions', () {
      test('saveGoal should call addGoal when adding a fresh record', () async {
        viewModel = SetGoalViewModel(mockRepository, exchangeService: mockExchangeService);
        
        when(() => mockRepository.addGoal(any())).thenAnswer((_) => Future.value());

        final success = await viewModel.saveGoal(name: 'Trip', target: 1000.0, currency: 'USD');

        expect(success, true);
        expect(viewModel.isSaving, false);
        verify(() => mockRepository.addGoal(any())).called(1);
        verifyNever(() => mockRepository.updateGoal(any()));
      });

      test('saveGoal should call updateGoal when handling an editing workflow', () async {
        final existing = SavingsGoal(
          id: 'goal_777',
          name: 'Bike',
          targetAmount: 500.0,
          currentAmount: 100.0,
          deadline: testDeadline,
          currency: 'EUR',
          targetBaseAmount: 540.0,
          currentBaseAmount: 108.0,
        );
        
        viewModel = SetGoalViewModel(mockRepository, existingGoal: existing, exchangeService: mockExchangeService);
        when(() => mockRepository.updateGoal(any())).thenAnswer((_) => Future.value());

        final success = await viewModel.saveGoal(name: 'New Bike', target: 600.0, currency: 'EUR');

        expect(success, true);
        verify(() => mockRepository.updateGoal(any())).called(1);
        verifyNever(() => mockRepository.addGoal(any()));
      });

      test('should return false if saving exception occurs in the data repository', () async {
        viewModel = SetGoalViewModel(mockRepository, exchangeService: mockExchangeService);
        when(() => mockRepository.addGoal(any())).thenThrow(Exception('DB Error'));

        final success = await viewModel.saveGoal(name: 'Error Goal', target: 10.0, currency: 'USD');

        expect(success, false);
        expect(viewModel.isSaving, false); // Ensures finally block safely turns off loading indicator
      });
    });

    group('Delete Actions', () {
      test('should return false cleanly if trying to delete without a valid goal context', () async {
        viewModel = SetGoalViewModel(mockRepository, exchangeService: mockExchangeService); // No existing goal passed

        final success = await viewModel.deleteGoal();

        expect(success, false);
        verifyNever(() => mockRepository.deleteGoal(any()));
      });

      test('should route deletion request to repository when valid goal id exists', () async {
        final existing = SavingsGoal(
          id: 'goal_to_delete',
          name: 'Old Goal',
          targetAmount: 100.0,
          currentAmount: 0.0,
          deadline: testDeadline,
          currency: 'USD',
          targetBaseAmount: 100.0,
          currentBaseAmount: 0.0,
        );
        
        viewModel = SetGoalViewModel(mockRepository, existingGoal: existing, exchangeService: mockExchangeService);
        when(() => mockRepository.deleteGoal('goal_to_delete')).thenAnswer((_) => Future.value());

        final success = await viewModel.deleteGoal();

        expect(success, true);
        verify(() => mockRepository.deleteGoal('goal_to_delete')).called(1);
      });
    });
  });
}