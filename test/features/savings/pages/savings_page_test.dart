import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/features/savings/pages/savings_page.dart';
import 'package:personal_fin/features/savings/view_models/savings_view_model.dart';
import 'package:personal_fin/models/savings.dart';
import '../../../helpers/test_helpers.dart';

class MockSavingsViewModel extends Mock implements SavingsViewModel {}


void main() {
  late MockSavingsViewModel mockVM;
  late TestDependencyManager deps;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    mockVM = MockSavingsViewModel();
    deps = TestDependencyManager();
  });

  
  testWidgets('shows CircularProgressIndicator when loading', (tester) async {
    when(() => mockVM.isLoading).thenReturn(true);
    when(() => mockVM.errorMessage).thenReturn(null);

    await tester.pumpWidget(deps.wrap(
      const SavingsViewContent(),
      extraProviders: [
        ChangeNotifierProvider<SavingsViewModel>.value(value: mockVM),
      ]
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows Error State when there is an error message', (tester) async {
    when(() => mockVM.isLoading).thenReturn(false);
    when(() => mockVM.errorMessage).thenReturn('Network Timeout');

    await tester.pumpWidget(deps.wrap(
      const SavingsViewContent(),
      extraProviders: [
        ChangeNotifierProvider<SavingsViewModel>.value(value: mockVM),
      ]
    ));

    expect(find.text('Network Timeout'), findsOneWidget);
    expect(find.text('failed_to_load_goals'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('shows Empty State when no goals are present', (tester) async {
    when(() => mockVM.isLoading).thenReturn(false);
    when(() => mockVM.errorMessage).thenReturn(null);
    when(() => mockVM.goals).thenReturn([]);

    await tester.pumpWidget(deps.wrap(
      const SavingsViewContent(),
      extraProviders: [
        ChangeNotifierProvider<SavingsViewModel>.value(value: mockVM),
      ]
    ));

    expect(find.text('no_goals_yet'), findsOneWidget);
    expect(find.text('create_goal'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('shows Savings Overview and goal list when data exists', (tester) async {
    final mockGoals = [
      SavingsGoal(id: '1', name: 'Car', targetAmount: 5000, currentAmount: 1000, deadline: DateTime.now().add(const Duration(days: 30))),
    ];

    when(() => mockVM.isLoading).thenReturn(false);
    when(() => mockVM.errorMessage).thenReturn(null);
    when(() => mockVM.goals).thenReturn(mockGoals);
    when(() => mockVM.overallProgress).thenReturn(0.2);
    when(() => mockVM.totalTarget).thenReturn(5000.0);
    when(() => mockVM.totalSaved).thenReturn(1000.0);

    await tester.pumpWidget(deps.wrap(
      const SavingsViewContent(),
      extraProviders: [
        ChangeNotifierProvider<SavingsViewModel>.value(value: mockVM),
      ]
    ));

    expect(find.text('savings_overview'), findsOneWidget);
    expect(find.text('20%'), findsNWidgets(2)); // Progress
    expect(find.text('1'), findsOneWidget);    // Goal count
    
    // Check if the goal list header appears
    expect(find.text('your_goals'), findsOneWidget);
  });
}