import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/savings/widgets/currency_input_field.dart';
import '../../../helpers/test_helpers.dart'; 

void main() {
  late TestDependencyManager deps;
  late TextEditingController controller;

  setUp(() {
    deps = TestDependencyManager();
    controller = TextEditingController();
    
  });

  tearDown(() {
    controller.dispose();
  });

  group('CurrencyInputField Tests -', () {
    testWidgets('displays the correct currency symbol as prefix', (tester) async {
      await tester.pumpWidget(deps.wrap(
        CurrencyInputField(
          controller: controller,
          labelText: 'Amount',
        ),
      ));

      await tester.tap(find.byType(TextFormField));
      await tester.pump(); 
      await tester.pumpAndSettle();

      expect(find.textContaining('Ksh'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
    });

    testWidgets('does not show prefix if symbol is empty', (tester) async {
      when(() => deps.mockCurrency.symbol).thenReturn(''); 
    
      await tester.pumpWidget(deps.wrap(
        CurrencyInputField(
          controller: controller,
          labelText: 'Amount',
        ),
      ));

      expect(find.text('Ksh'), findsNothing);
    });

    testWidgets('updates controller text when user types', (tester) async {
      await tester.pumpWidget(deps.wrap(
        CurrencyInputField(
          controller: controller,
          labelText: 'Amount',
        ),
      ));

      await tester.enterText(find.byType(TextFormField), '150.50');
      
      expect(controller.text, '150.50');
    });

    testWidgets('triggers validator correctly', (tester) async {
      String? validationResult;
      
      await tester.pumpWidget(deps.wrap(
        Material( // Required for validator feedback
          child: CurrencyInputField(
            controller: controller,
            labelText: 'Amount',
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required Field';
              return null;
            },
          ),
        ),
      ));

      // Trigger validation manually through the FormState or by interaction
      final formField = tester.widget<TextFormField>(find.byType(TextFormField));
      validationResult = formField.validator!('');

      expect(validationResult, 'Required Field');
    });

    testWidgets('respects the enabled property', (tester) async {
      await tester.pumpWidget(deps.wrap(
        CurrencyInputField(
          controller: controller,
          labelText: 'Amount',
          enabled: false,
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('calls onChanged callback', (tester) async {
      String changedValue = '';
      
      await tester.pumpWidget(deps.wrap(
        CurrencyInputField(
          controller: controller,
          labelText: 'Amount',
          onChanged: (val) => changedValue = val,
        ),
      ));

      await tester.enterText(find.byType(TextFormField), '200');
      expect(changedValue, '200');
    });
  });
}