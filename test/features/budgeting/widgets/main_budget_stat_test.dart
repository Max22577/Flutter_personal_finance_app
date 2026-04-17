import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
import 'package:personal_fin/features/budgeting/widgets/main_budget_stat.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late TestDependencyManager tdm;

  setUp(() {
    tdm = TestDependencyManager();
  });

  testWidgets('renders the correct label text', (tester) async {
    const testLabel = 'total_balance';
    
    await tester.pumpWidget(tdm.wrap(
      const MainBudgetStat(
        label: testLabel,
        amount: 50000.0,
      ),
    ));

    expect(find.text(testLabel), findsOneWidget);
  });

  testWidgets('renders CurrencyDisplay with stubbed formatted amount', (tester) async {
    const testAmount = 1250.50;

    await tester.pumpWidget(tdm.wrap(
      const MainBudgetStat(
        label: 'savings',
        amount: testAmount,
      ),
    ));

    expect(find.byType(CurrencyDisplay), findsOneWidget);

    expect(find.text('Ksh 1250.50', findRichText: true), findsOneWidget);
  });

  testWidgets('displays the wallet icon with correct color', (tester) async {
    await tester.pumpWidget(tdm.wrap(
      const MainBudgetStat(
        label: 'wallet',
        amount: 0.0,
      ),
    ));

    final iconFinder = find.byIcon(Icons.account_balance_wallet_rounded);
    expect(iconFinder, findsOneWidget);

    final Icon iconWidget = tester.widget(iconFinder);
    expect(iconWidget.color, equals(Colors.white));
  });

  testWidgets('verifies interaction with CurrencyFormatter', (tester) async {
    const testAmount = 99.99;

    await tester.pumpWidget(tdm.wrap(
      const MainBudgetStat(
        label: 'test',
        amount: testAmount,
      ),
    ));

    // Verify that the widget actually talked to your mock formatter
    verify(() => tdm.mockFormatter.formatDisplay(testAmount, any())).called(1);
  });
}