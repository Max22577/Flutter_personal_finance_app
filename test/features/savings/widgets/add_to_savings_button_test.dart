import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/features/savings/widgets/add_to_savings_button.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';
import '../../../helpers/test_helpers.dart';

// mock the callback to verify it gets called on success
abstract class SuccessCallback {
  void call();
}
class MockSuccessCallback extends Mock implements SuccessCallback {}
class MockSavingsRepository extends Mock implements SavingsRepository {}
void main() {
  late TestDependencyManager deps;
  late SavingsGoal testGoal;
  late MockSavingsRepository mockSavingsRepo;

  setUp(() {
    deps = TestDependencyManager();
    mockSavingsRepo = MockSavingsRepository();
    testGoal = SavingsGoal(
      id: 'goal_123',
      name: 'Trip to Japan',
      currentAmount: 100,
      targetAmount: 5000,
      deadline: DateTime.now().add(const Duration(days: 180)),
    );
  });

  group('AddToSavingsButton Tests -', () {
    testWidgets('renders the FloatingActionButton with correct label', (tester) async {
      await tester.pumpWidget(deps.wrap(
        AddToSavingsButton(goal: testGoal),
        extraProviders: [
          Provider<SavingsRepository>.value(value: mockSavingsRepo),
        ],
      ));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('add_to_savings'), findsOneWidget);
    });

    testWidgets('opens bottom sheet when pressed', (tester) async {
      await tester.pumpWidget(deps.wrap(
        AddToSavingsButton(goal: testGoal),
        extraProviders: [
          Provider<SavingsRepository>.value(value: mockSavingsRepo),
        ],
      ));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); 

      // Check for bottom sheet content
      expect(find.text('add_to_savings'), findsNWidgets(2)); // One on button, one in header
      expect(find.text('adding_to: Trip to Japan'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Amount and Note
    });

    testWidgets('shows validation error for empty amount', (tester) async {
      await tester.pumpWidget(deps.wrap(
        AddToSavingsButton(goal: testGoal),
        extraProviders: [
          Provider<SavingsRepository>.value(value: mockSavingsRepo),
        ],
      ));

      // Open sheet
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap "Add" without entering anything
      await tester.tap(find.text('add'));
      await tester.pump();

      // Check for validation message (assuming 'required' is the translation)
      expect(find.text('required'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid amount (zero/negative)', (tester) async {
      await tester.pumpWidget(deps.wrap(
        AddToSavingsButton(goal: testGoal),
        extraProviders: [
          Provider<SavingsRepository>.value(value: mockSavingsRepo),
        ],
      ));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter "0"
      await tester.enterText(find.byType(TextFormField).first, '0');
      await tester.tap(find.text('add'));
      await tester.pump();

      expect(find.text('err_invalid_amount'), findsOneWidget);
    });
  });
}