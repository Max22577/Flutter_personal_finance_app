import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/transactions/pages/transactions.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_history.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_form.dart';
import '../../../helpers/test_nav_helpers.dart';

void main() {
  late TestNavigationDependencyManager deps;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });
  
  setUp(() {
    deps = TestNavigationDependencyManager();
        
    when(() => deps.mockNav.selectedIndex).thenReturn(1);
    when(() => deps.mockNav.currentActions).thenReturn([]);
    when(() => deps.mockNav.setActions(any())).thenReturn(null);
  });

  group('TransactionsPage Tests -', () {
    testWidgets('renders TransactionHistory and FAB', (tester) async {
      await tester.pumpWidget(deps.wrap(
        const TransactionsPage(isActive: true),
      ));

      expect(find.byType(TransactionHistory), findsOneWidget);

      expect(find.text('new_transaction'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('opens TransactionForm when FAB is pressed', (tester) async {
      await tester.pumpWidget(deps.wrap(
        const TransactionsPage(isActive: true),
      ));

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      
      // showModalBottomSheet has an entrance animation
      await tester.pumpAndSettle();

      // Verify the form is now visible
      expect(find.byType(TransactionForm), findsOneWidget);
    });

    testWidgets('updates NavigationProvider actions on init', (tester) async {
      await tester.pumpWidget(deps.wrap(
        const TransactionsPage(isActive: true),
      ));

      // Wait for the post-frame callback in initState
      await tester.pump();

      // Verify that the page tried to set the App Bar actions
      verify(() => deps.mockNav.setActions(any())).called(greaterThan(0));
    });

    testWidgets('clears actions when disposed', (tester) async {
      await tester.pumpWidget(deps.wrap(
        const TransactionsPage(isActive: true),
      ));

      // Replace the widget with something else to trigger dispose
      await tester.pumpWidget(deps.wrap(const SizedBox()));
      await tester.pump(); // Handle the post-frame callback

      // Verify it tried to set actions to empty []
      verify(() => deps.mockNav.setActions([])).called(1);
    });
  });
}