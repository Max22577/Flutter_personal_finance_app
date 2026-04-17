import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_list_item.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:intl/intl.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late TestDependencyManager deps;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    deps = TestDependencyManager();
  });

  group('TransactionListItem Widget Tests -', () {
    final testDate = DateTime(2026, 4, 9); 
    
    final incomeTx = Transaction(
      id: 'tx_income',
      userId: 'user123',
      title: 'Dividend',
      amount: 150.0,
      categoryId: 'investment',
      date: testDate,
      type: 'Income',
    );

    final expenseTx = Transaction(
      id: 'tx_expense',
      userId: 'user123',
      title: 'Coffee',
      amount: 4.50,
      categoryId: 'food',
      date: testDate,
      type: 'Expense',
    );

    testWidgets('renders title and formatted date correctly', (tester) async {
      await tester.pumpWidget(deps.wrap(
        TransactionListItem(
          transaction: incomeTx,
          categoryName: 'Investments',
        ),
      ));

      // Title
      expect(find.text('Dividend'), findsOneWidget);

      // Date formatting (yMMMMd: April 9, 2026)
      final expectedDate = DateFormat.yMMMMd('en').format(testDate);
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('shows arrow_upward icon for income', (tester) async {
      await tester.pumpWidget(deps.wrap(
        TransactionListItem(
          transaction: incomeTx,
          categoryName: 'Investments',
        ),
      ));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_upward);
    });

    testWidgets('shows arrow_downward icon for expense', (tester) async {
      await tester.pumpWidget(deps.wrap(
        TransactionListItem(
          transaction: expenseTx,
          categoryName: 'Food',
        ),
      ));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_downward);
    });

    testWidgets('respects compactAmount and alwaysShowSign flags', (tester) async {

      await tester.pumpWidget(deps.wrap(
        TransactionListItem(
          transaction: incomeTx,
          categoryName: 'Investments',
          compactAmount: true,
          alwaysShowSign: false,
        ),
      ));

      final currencyDisplay = tester.widget(find.byType(CurrencyDisplay).first) as dynamic;
      
      expect(currencyDisplay.compact, isTrue);
      expect(currencyDisplay.showSign, isFalse);
    });
  });
}