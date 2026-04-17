import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/features/savings/pages/set_goal_page.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/models/savings.dart';
import '../../../helpers/test_helpers.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

void main() {
  late MockSavingsRepository mockRepo;
  late TestDependencyManager deps;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    mockRepo = MockSavingsRepository();
    deps = TestDependencyManager();

    // Setup default repository behavior
    registerFallbackValue(SavingsGoal(name: '', targetAmount: 0, currentAmount: 0, deadline: DateTime.now()));
  });

  testWidgets('renders empty form in Create mode', (tester) async {
    await tester.pumpWidget(deps.wrap(
      SetGoalPage(),
      extraProviders: [
        Provider<SavingsRepository>.value(value: mockRepo),
      ]
    ));

    expect(find.text('set_savings_goal'), findsOneWidget);

    expect(find.text('create_goal_btn', skipOffstage: false), findsOneWidget);
      
    expect(find.byIcon(Icons.flag), findsOneWidget); // Prefix icon for name field
  });

  testWidgets('renders pre-filled form in Edit mode', (tester) async {
    final goal = SavingsGoal(id: '123', name: 'Buy a Laptop', targetAmount: 1500, currentAmount: 0, deadline: DateTime.now());
    
    await tester.pumpWidget(deps.wrap(
      SetGoalPage(existingGoal: goal),
      extraProviders: [
        Provider<SavingsRepository>.value(value: mockRepo),
      ]
    ));

    expect(find.text('edit_goal'), findsOneWidget);
    expect(find.text('Buy a Laptop'), findsOneWidget);
    expect(find.text('1500.0'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('shows validation errors when saving empty form', (tester) async {
    await tester.pumpWidget(deps.wrap(
      SetGoalPage(),
      extraProviders: [
        Provider<SavingsRepository>.value(value: mockRepo),
      ]
    ));

    final btnFinder = find.text('create_goal_btn');

    await tester.dragUntilVisible(
      btnFinder,
      find.byType(ListView), 
      const Offset(0, -500), 
    );
    
    await tester.pumpAndSettle(); 

    await tester.tap(btnFinder);
    await tester.pumpAndSettle();
    await tester.pump(); 

    expect(find.text('err_no_name'), findsOneWidget);
    expect(find.text('err_no_amount'), findsOneWidget);
  });

  testWidgets('calls repository save when form is valid', (tester) async {
    const goalId = 'g1';
    const amount = 50.0;
    const defaultNote = 'Saved a bit extra!';
    // Mock the repo to return success
    when(() => mockRepo.addToGoal(
          goalId: goalId,
          amount: amount,
          note: defaultNote,
          defaultNote: defaultNote,
        )
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(deps.wrap(
      SetGoalPage(),
      extraProviders: [
        Provider<SavingsRepository>.value(value: mockRepo),
      ]
    ));

    await tester.enterText(find.byType(TextFormField).first, 'Emergency Fund');

    await tester.enterText(find.byType(TextFormField).last, '5000');
    
    await tester.pump(); 
    
    final btnFinder = find.text('create_goal_btn');

    // 3. Scroll down until the button is hit-testable
    // We drag the ListView (found byType) upwards (-500 pixels) until the button is visible
    await tester.dragUntilVisible(
      btnFinder,
      find.byType(ListView), // The scrollable container
      const Offset(0, -500), // Swipe up 500 pixels at a time
    );
    
    await tester.pumpAndSettle(); // Wait for scroll animation to stop

    // 4. Now the tap will work because the widget is "Onstage"
    await tester.tap(btnFinder);
  
    await tester.pumpAndSettle(); // Wait for async logic and pop

    // Verify the repository was called
    verify(() => mockRepo.addGoal(any())).called(1);
    expect(find.byType(SetGoalPage), findsNothing); // Verify page popped
  });

  testWidgets('shows delete confirmation and handles deletion', (tester) async {
    final goal = SavingsGoal(id: '123', name: 'Trip', targetAmount: 100, currentAmount: 0, deadline: DateTime.now());
    when(() => mockRepo.deleteGoal(any())).thenAnswer((_) async => true);

    await tester.pumpWidget(deps.wrap(
      SetGoalPage(existingGoal: goal),
      extraProviders: [
        Provider<SavingsRepository>.value(value: mockRepo),
      ]));

    // Tap Delete Icon
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle(); // Wait for dialog animation

    // Verify dialog content
    expect(find.text('delete_goal'), findsOneWidget);
    
    // Confirm Delete
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.deleteGoal('123')).called(1);
    expect(find.text('goal_deleted_successfully'), findsOneWidget); // SnackBar
  });
}