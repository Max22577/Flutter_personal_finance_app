import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_history.dart';
import 'package:personal_fin/features/transactions/widgets/state/loading_state.dart';
import 'package:personal_fin/features/transactions/widgets/state/error_state.dart';
import 'package:personal_fin/features/transactions/widgets/state/empty_state.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_group.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/models/transaction.dart';
import '../../../helpers/test_helpers.dart';

class MockTransactionViewModel extends Mock implements TransactionViewModel {}

void main() {
  late TestDependencyManager deps;
  late MockTransactionViewModel mockVM;

  setUp(() {
    deps = TestDependencyManager();
    mockVM = MockTransactionViewModel();

    when(() => mockVM.isLoading).thenReturn(false);
    when(() => mockVM.errorMessage).thenReturn(null);
    when(() => mockVM.transactions).thenReturn([]);
    when(() => mockVM.groupedTransactions).thenReturn({});
    when(() => mockVM.categories).thenReturn([]);
  });

  group('TransactionHistory Widget Tests -', () {
    testWidgets('shows LoadingState when viewModel is loading', (tester) async {
      when(() => mockVM.isLoading).thenReturn(true);

      await tester.pumpWidget(deps.wrap(
        const TransactionHistory(isActive: true),
        extraProviders: [ChangeNotifierProvider<TransactionViewModel>.value(value: mockVM)],
      ));

      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('shows ErrorState with correct message when error occurs', (tester) async {
      const errorMsg = 'Failed to fetch data';
      when(() => mockVM.errorMessage).thenReturn(errorMsg);

      await tester.pumpWidget(deps.wrap(
        const TransactionHistory(isActive: true),
        extraProviders: [ChangeNotifierProvider<TransactionViewModel>.value(value: mockVM)],
      ));

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text(errorMsg), findsOneWidget);
    });

    testWidgets('shows EmptyState when there are no transactions', (tester) async {
      when(() => mockVM.transactions).thenReturn([]);

      await tester.pumpWidget(deps.wrap(
        const TransactionHistory(isActive: true),
        extraProviders: [ChangeNotifierProvider<TransactionViewModel>.value(value: mockVM)],
      ));

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('renders TransactionGroupWidgets when transactions exist', (tester) async {
      final date = DateTime(2026, 4, 9);
      final tx = Transaction(id: '1', userId: 'user1', title: 'Test', amount: 10, categoryId: '1', date: date, type: 'Expense');
      
      when(() => mockVM.transactions).thenReturn([tx]);
      when(() => mockVM.groupedTransactions).thenReturn({date: [tx]});

      await tester.pumpWidget(deps.wrap(
        const TransactionHistory(isActive: true),
        extraProviders: [ChangeNotifierProvider<TransactionViewModel>.value(value: mockVM)],
      ));

      expect(find.byType(TransactionGroupWidget), findsOneWidget);
    });

    testWidgets('deletion flow: shows dialog and calls viewModel on confirm', (tester) async {
      // Arrange
      final date = DateTime.now();
      final tx = Transaction(id: 'tx_123', userId: 'user1', title: 'Dinner', amount: 30, categoryId: '1', date: date, type: 'Expense');
      
      when(() => mockVM.transactions).thenReturn([tx]);
      when(() => mockVM.groupedTransactions).thenReturn({date: [tx]});
      when(() => mockVM.deleteTransaction(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(deps.wrap(
        const TransactionHistory(isActive: true),
        extraProviders: [ChangeNotifierProvider<TransactionViewModel>.value(value: mockVM)],
      ));

      // Act: Trigger the delete from the child widget
      final groupWidget = tester.widget<TransactionGroupWidget>(find.byType(TransactionGroupWidget));
      groupWidget.onDelete(tx);
      await tester.pumpAndSettle(); // Wait for dialog to appear

      // Assert: Verify Dialog is shown
      final dialogFinder = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialogFinder, matching: find.textContaining('Dinner')), 
        findsOneWidget
      );

      // Act: Tap "Delete" in the dialog
      final deleteBtnFinder = find.descendant(
        of: dialogFinder, 
        matching: find.text('delete'),
      );
      
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle(); // Wait for dialog to close and SnackBar


      // 5. Assert: Verify ViewModel was called and SnackBar appeared
      verify(() => mockVM.deleteTransaction('tx_123')).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('deleted'), findsOneWidget);
    });
  });
}