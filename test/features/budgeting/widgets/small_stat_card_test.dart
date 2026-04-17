import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/features/budgeting/widgets/small_stat_card.dart';

void main() {
  Widget createWidgetUnderTest({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double value,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SmallStatCard(
          icon: icon,
          iconColor: iconColor,
          label: label,
          value: value,
        ),
      ),
    );
  }

  testWidgets('renders correct label and formatted value', (tester) async {
    const testLabel = 'Completed Goals';
    const testValue = 12.0;

    await tester.pumpWidget(createWidgetUnderTest(
      icon: Icons.check_circle,
      iconColor: Colors.green,
      label: testLabel,
      value: testValue,
    ));

    expect(find.text(testLabel), findsOneWidget);

    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('renders the correct icon with specified color', (tester) async {
    const testIcon = Icons.savings;
    const testColor = Colors.blue;

    await tester.pumpWidget(createWidgetUnderTest(
      icon: testIcon,
      iconColor: testColor,
      label: 'Savings',
      value: 100,
    ));

    final iconFinder = find.byIcon(testIcon);
    expect(iconFinder, findsOneWidget);

    final Icon iconWidget = tester.widget(iconFinder);
    expect(iconWidget.color, equals(testColor));
  });

  testWidgets('handles large values by converting to int string', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      icon: Icons.trending_up,
      iconColor: Colors.orange,
      label: 'Total Views',
      value: 1500.75,
    ));

    // Your code uses value.toInt().toString(), so 1500.75 should become '1500'
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('1500.75'), findsNothing);
  });
}