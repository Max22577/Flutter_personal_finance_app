import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/budgeting/widgets/budget_edit_dialog.dart';
import 'package:personal_fin/models/category.dart';
import '../../../helpers/test_helpers.dart';


// Mock the save callback function
abstract class SaveCallback {
  Future<void> call(String id, double amount, String monthYear);
}
class MockSaveCallback extends Mock implements SaveCallback {}

void main() {
  late TestDependencyManager tdm;
  late MockSaveCallback mockSave;
  late Category testCategory;

  setUp(() {
    tdm = TestDependencyManager();
    mockSave = MockSaveCallback();
    testCategory = Category(id: 'cat_1', name: 'Food');
    
    // Register fallback for the SaveCallback arguments
    registerFallbackValue(0.0);
  });

  testWidgets('initializes with current budget in the text field', (tester) async {
    await tester.pumpWidget(tdm.wrap(
      BudgetEditDialog(
        category: testCategory,
        currentBudget: 150.50,
        monthYear: '2026-04',
        onSave: mockSave.call,
      ),
    ));

    // Wait for the TweenAnimationBuilder to finish scaling
    await tester.pumpAndSettle();

    // Verify initial value in text field
    expect(find.text('150.50'), findsOneWidget);

    expect(find.text('Food'), findsOneWidget);
    // Verify previous budget badge exists
    expect(find.textContaining('151', findRichText: true), findsOneWidget); 
    expect(find.textContaining('150', findRichText: true), findsOneWidget);
  });

  testWidgets('triggers onSave and shows success snackbar when valid', (tester) async {
    // Stub the save function to return successfully
    when(() => mockSave(any(), any(), any())).thenAnswer((_) async => {});

    await tester.pumpWidget(tdm.wrap(
      BudgetEditDialog(
        category: testCategory,
        currentBudget: 0.0,
        monthYear: '2026-04',
        onSave: mockSave.call,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '500.00');
    
    await tester.tap(find.text('update_budget'));
    
    // Pump once to trigger the VM's updateBudget
    await tester.pump(); 
    
    // Verify mock was called with correct values
    verify(() => mockSave('cat_1', 500.0, '2026-04')).called(1);
    await tester.idle();

    await tester.pump();

    // Wait for navigator.pop and SnackBar animation
    await tester.pump(const Duration(milliseconds: 100));

    // Verify the SnackBar 
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Food'), findsNWidgets(2));

  });

  testWidgets('shows validation error for invalid input', (tester) async {
    await tester.pumpWidget(tdm.wrap(
      BudgetEditDialog(
        category: testCategory,
        currentBudget: 0.0,
        monthYear: '2026-04',
        onSave: mockSave.call,
      ),
    ));
    await tester.pumpAndSettle();

    // Clear text and enter invalid string
    await tester.enterText(find.byType(TextFormField), 'not_a_number');
    await tester.tap(find.text('update_budget'));
    await tester.pump();

    // Verify error message from LanguageProvider stub
    expect(find.text('enter_valid_positive_amount'), findsOneWidget);
    
    // Verify save was NEVER called
    verifyNever(() => mockSave(any(), any(), any()));
  });

  testWidgets('cancels and closes the dialog when cancel is pressed', (tester) async {
    await tester.pumpWidget(tdm.wrap(
      BudgetEditDialog(
        category: testCategory,
        currentBudget: 10.0,
        monthYear: '2026-04',
        onSave: mockSave.call,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();

    // Verify the dialog is gone
    expect(find.byType(BudgetEditDialog), findsNothing);
  });
}