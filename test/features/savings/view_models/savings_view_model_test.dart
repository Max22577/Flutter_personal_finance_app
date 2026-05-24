import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/features/savings/view_models/savings_view_model.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:rxdart/rxdart.dart';


class MockSavingsRepository extends Mock implements SavingsRepository {}
class MockExchangeRateService extends Mock implements ExchangeRateService {}
class MockCurrencyProvider extends Mock implements CurrencyProvider {}

void main() {
  late SavingsViewModel viewModel;
  late MockSavingsRepository mockRepository;
  late MockExchangeRateService mockExchangeService;
  late MockCurrencyProvider mockCurrencyProvider;

  setUp(() {
    mockRepository = MockSavingsRepository();
    mockExchangeService = MockExchangeRateService();
    mockCurrencyProvider = MockCurrencyProvider();

    // Stub defaults
    when(() => mockExchangeService.fromBase(any(), any()))
        .thenAnswer((inv) => inv.positionalArguments[0] as double);
    
    when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
    when(() => mockCurrencyProvider.currencyStream).thenAnswer((_) => Stream.value('USD'));
    
    viewModel = SavingsViewModel(mockRepository, mockExchangeService, mockCurrencyProvider);
  });

  group('SavingsViewModel Tests', () {
    final testDeadline = DateTime(2026, 12, 31);

    final sampleGoals = [
      SavingsGoal(
        id: 'goal_1',
        name: 'Emergency Fund',
        targetAmount: 1000.0,
        currentAmount: 400.0,
        deadline: testDeadline,
        currency: 'USD',
        targetBaseAmount: 1000.0, // Base matching for calculation rules
        currentBaseAmount: 400.0,
      ),
      SavingsGoal(
        id: 'goal_2',
        name: 'Holiday Vacation',
        targetAmount: 2000.0,
        currentAmount: 600.0,
        deadline: testDeadline,
        currency: 'EUR',
        targetBaseAmount: 2000.0, 
        currentBaseAmount: 600.0,
      ),
    ];

    group('stateStream (Data Transformation Processing)', () {
      test('should calculate aggregated state correctly when goals stream emits data', () async {
        // Arrange
        final goalsController = BehaviorSubject<List<SavingsGoal>>.seeded(sampleGoals);
        final currController = BehaviorSubject<String>.seeded('USD');
        
        when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
        when(() => mockRepository.goalsStream).thenAnswer((_) => goalsController.stream);
        when(() => mockCurrencyProvider.currencyStream).thenAnswer((_) => currController.stream);

        // Act & Assert
        expect(
          viewModel.stateStream,
          emits(isA<SavingsState>()
              .having((s) => s.goals.length, 'goals count', 2)
              .having((s) => s.totalTargetBase, 'total target', 3000.0) // 1000 + 2000
              .having((s) => s.totalSavedBase, 'total saved', 1000.0)    // 400 + 600
              .having((s) => s.remainingBase, 'remaining base', 2000.0) // 3000 - 1000
              .having((s) => s.overallProgress, 'progress math', 0.3333333333333333)), // 1000 / 3000
        );

        await goalsController.close();
        await currController.close();
      });

      test('should yield clean zeroed indicators safely when goal stream contains empty data lists', () async {
        // Arrange
        final currController = BehaviorSubject<String>.seeded('USD');
        
        when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
        when(() => mockRepository.goalsStream).thenAnswer((_) => Stream.value([]));
        when(() => mockCurrencyProvider.currencyStream).thenAnswer((_) => currController.stream);

        // Act & Assert
        expect(
          viewModel.stateStream,
          emits(isA<SavingsState>()
              .having((s) => s.goals, 'empty validation checking', isEmpty)
              .having((s) => s.totalTargetBase, 'total target zeroed', 0.0)
              .having((s) => s.totalSavedBase, 'total saved zeroed', 0.0)
              .having((s) => s.remainingBase, 'remaining base zeroed', 0.0)
              .having((s) => s.overallProgress, 'progress handle zero division fallback', 0.0)),
        );
        await currController.close();
      });

      test('should clamp metrics elegantly if total base savings overflow target base rulesets', () async {
        // Arrange
        final overflowGoal = [
          SavingsGoal(
            id: 'goal_overflow',
            name: 'Surplus Account',
            targetAmount: 500.0,
            currentAmount: 600.0,
            deadline: testDeadline,
            currency: 'USD',
            targetBaseAmount: 500.0,
            currentBaseAmount: 600.0, // Exceeds target amount
          ),
        ];
        
        final goalsController = BehaviorSubject<List<SavingsGoal>>.seeded(overflowGoal);
        final currController = BehaviorSubject<String>.seeded('USD');
        
        when(() => mockCurrencyProvider.currentCurrency).thenReturn('USD');
        when(() => mockRepository.goalsStream).thenAnswer((_) => goalsController.stream);
        when(() => mockCurrencyProvider.currencyStream).thenAnswer((_) => currController.stream);

        // Act & Assert
        expect(
          viewModel.stateStream,
          emits(isA<SavingsState>()
              .having((s) => s.remainingBase, 'clamped remaining target lowest limit', 0.0) // Ensures it clamps to 0.0 instead of falling into negative numbers
              .having((s) => s.overallProgress, 'clamped maximal ratio value progress limit', 1.0)), // Caps explicitly at 1.0 (100%)
        );

        await goalsController.close();
        await currController.close();
      });
    });

    group('Mutations & Actions Workflow Verification', () {
      test('deleteGoal should seamlessly marshal method parameter invocations to repo matching layers', () async {
        // Arrange
        when(() => mockRepository.deleteGoal('goal_1')).thenAnswer((_) => Future.value());

        // Act
        await viewModel.deleteGoal('goal_1');

        // Assert
        verify(() => mockRepository.deleteGoal('goal_1')).called(1);
      });

      test('refresh should notify layout frames and resolve its asynchronous padding timer accurately', () async {
        // Arrange
        int notificationCallCounter = 0;
        viewModel.addListener(() => notificationCallCounter++);

        // Act
        final refreshFuture = viewModel.refresh();
        
        // Ensure notifyListeners fired immediately on interaction kick start
        expect(notificationCallCounter, 1);

        await refreshFuture;

        // Verify completion handles fine
        expect(notificationCallCounter, 1); 
      });
    });
  });
}