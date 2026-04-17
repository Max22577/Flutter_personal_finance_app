import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_tile.dart';
import 'package:personal_fin/models/transaction.dart';
import '../../../helpers/test_helpers.dart';


void main() {
  late TestDependencyManager deps;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    deps = TestDependencyManager();
  });

  group('TransactionTile Widget Tests -', () {
    final testDate = DateTime(2026, 4, 9, 14, 30); // 2:30 PM
    
    final incomeTx = Transaction(
      id: '1',
      userId: 'user123',
      title: 'Salary',
      amount: 5000.0,
      categoryId: 'income_cat',
      date: testDate,
      type: 'Income',
    );

    final expenseTx = Transaction(
      id: '2',
      userId: 'user123',
      title: 'Grocery',
      amount: 50.0,
      categoryId: 'food_cat',
      date: testDate,
      type: 'Expense',
    );

    testWidgets('renders income specific UI correctly', (tester) async {
      await tester.pumpWidget(deps.wrap(
        TransactionTile(
          transaction: incomeTx,
          categoryName: 'Salary',
          onEdit: () {},
          onDelete: () {},
        ),
      ));

      expect(find.text('Salary'), findsNWidgets(2)); 
      
      expect(find.text('2:30 PM'), findsOneWidget);

      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.icon, Icons.arrow_upward_rounded);
    });

    testWidgets('renders expense specific UI correctly', (tester) async {
      await tester.pumpWidget(deps.wrap(
        TransactionTile(
          transaction: expenseTx,
          categoryName: 'Food',
          onEdit: () {},
          onDelete: () {},
        ),
      ));

      expect(find.text('Grocery'), findsOneWidget);
      
      // Check for the downward arrow icon (Expense)
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.icon, Icons.arrow_downward_rounded);
    });

    testWidgets('triggers onEdit callback when edit button is pressed', (tester) async {
      bool editCalled = false;

      await tester.pumpWidget(deps.wrap(
        TransactionTile(
          transaction: expenseTx,
          categoryName: 'Food',
          onEdit: () => editCalled = true,
          onDelete: () {},
        ),
      ));

      // Find the button by its label 'edit' (which comes from mockLang.translate)
      await tester.tap(find.text('edit'));
      await tester.pump();

      expect(editCalled, isTrue);
    });

    testWidgets('triggers onDelete callback when delete button is pressed', (tester) async {
      bool deleteCalled = false;

      await tester.pumpWidget(deps.wrap(
        TransactionTile(
          transaction: expenseTx,
          categoryName: 'Food',
          onEdit: () {},
          onDelete: () => deleteCalled = true,
        ),
      ));

      await tester.tap(find.text('delete'));
      await tester.pump();

      expect(deleteCalled, isTrue);
    });
  });
}