import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/features/budgeting/pages/budgeting_page.dart';
import 'package:personal_fin/features/budgeting/view_models/budgeting_view_model.dart';
import 'package:personal_fin/features/budgeting/widgets/budget_category_card.dart';
import 'package:personal_fin/features/budgeting/widgets/month_selector.dart';
import 'package:personal_fin/core/widgets/empty_state.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:personal_fin/features/budgeting/widgets/main_budget_stat.dart';
import 'package:personal_fin/features/budgeting/widgets/small_stat_card.dart';
import 'package:personal_fin/models/category.dart';
import '../../../helpers/test_nav_helpers.dart';

class MockBudgetingViewModel extends Mock implements BudgetingViewModel {}
class MockBudgetingState extends Mock implements BudgetingState {}

void main() {
  late TestNavigationDependencyManager tdm;
  late MockBudgetingViewModel mockVM;
  late DateTime testDate;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    tdm = TestNavigationDependencyManager();
    mockVM = MockBudgetingViewModel();
    testDate = DateTime(2026, 4); 

    when(() => mockVM.errorMessage).thenReturn(null);
    when(() => mockVM.currentState).thenReturn(null);
    when(() => mockVM.selectedDate).thenReturn(testDate);
    
    when(() => mockVM.refreshData()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return tdm.wrap(
      ChangeNotifierProvider<BudgetingViewModel>.value(
        value: mockVM,
        child: const BudgetingPage(),
      ),
    );
  }

  group('BudgetingPage State Tests', () {
    testWidgets('shows LoadingState when currentState is null', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LoadingState), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
    });

    testWidgets('shows ErrorState and triggers retry when errorMessage is present', (tester) async {
      when(() => mockVM.errorMessage).thenReturn('Failed to load budgets');
      when(() => mockVM.retry()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Failed to load budgets'), findsOneWidget);

      await tester.tap(find.text('retry')); 
      verify(() => mockVM.retry()).called(1);
    });

    testWidgets('shows main content with stats and list on success state', (tester) async {
      final mockState = MockBudgetingState();
      final testCategory = Category(id: '1', name: 'food');

      when(() => mockState.totalBudget).thenReturn(5000.0);
      when(() => mockState.activeBudgetsCount).thenReturn(2);
      when(() => mockState.totalCategoryCount).thenReturn(5);
      when(() => mockState.categories).thenReturn([testCategory]);
      when(() => mockState.budgetMap).thenReturn({'1': 1000.0});
      when(() => mockState.transactions).thenReturn([]);
      when(() => mockState.monthYear).thenReturn('2026-04');

      when(() => mockVM.currentState).thenReturn(mockState);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MonthSelectorCard), findsOneWidget);
      expect(find.byType(MainBudgetStat), findsOneWidget);
      expect(find.byType(SmallStatCard), findsNWidgets(2)); 
      expect(find.byType(BudgetCategoryCard), findsOneWidget);

      expect(find.textContaining('active'), findsOneWidget);
      expect(find.textContaining('categories_count'), findsOneWidget);
    });
  });

  group('BudgetingPage Interactions', () {
    testWidgets('pull to refresh triggers vm.refreshData', (tester) async {
      // Setup successful data state to allow scrolling
      final mockState = MockBudgetingState();
      when(() => mockState.categories).thenReturn([]);
      when(() => mockState.totalBudget).thenReturn(0.0);
      when(() => mockState.activeBudgetsCount).thenReturn(0);
      when(() => mockState.totalCategoryCount).thenReturn(0);
      when(() => mockVM.currentState).thenReturn(mockState);

      await tester.pumpWidget(buildTestWidget());

      // Perform a drag gesture to trigger RefreshIndicator
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify the VM was asked to refresh
      verify(() => mockVM.refreshData()).called(1);
    });

    testWidgets('NavigationProvider sets AppBar actions when selectedIndex is 2', (tester) async {
      // Setup to trigger the _onNavChanged logic
      when(() => tdm.mockNav.selectedIndex).thenReturn(2);
      when(() => tdm.mockNav.currentActions).thenReturn([]);
      
      await tester.pumpWidget(buildTestWidget());

      tdm.mockNav.notifyListeners(); 
  
      // Pump to process the resulting state changes
      await tester.pump(); 

      // Verify that the UI asked the NavigationProvider to set actions
      verify(() => tdm.mockNav.setActions(any())).called(greaterThan(0));
    });
    
    testWidgets('clears AppBar actions on dispose', (tester) async {
      when(() => tdm.mockNav.selectedIndex).thenReturn(2);
      await tester.pumpWidget(buildTestWidget());
      
      // Pump a different widget to force disposal of BudgetingPage
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Gone'))));
      
      // Allow the post-frame callback to execute
      await tester.pumpAndSettle();

      // Verify it cleared the actions array
      verify(() => tdm.mockNav.setActions([])).called(greaterThan(0));
    });
  });
}