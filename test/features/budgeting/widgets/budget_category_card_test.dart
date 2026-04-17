import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/features/budgeting/widgets/budget_category_card.dart';
import 'package:personal_fin/models/category.dart';
import '../../../helpers/test_helpers.dart';


void main() {
  late TestDependencyManager deps;
  late Category testCategory;
  late ColorScheme testColors;
  bool editPressed = false;

  setUp(() {
    deps = TestDependencyManager();
    testCategory = Category(id: '1', name: 'food');
    testColors = ColorScheme.fromSeed(seedColor: Colors.blue);
    editPressed = false;
  });

  testWidgets('displays category name, budget, and spending correctly', (tester) async {
    await tester.pumpWidget(deps.wrap(
      BudgetCategoryCard(
        category: testCategory,
        currentBudget: 1000,
        currentSpending: 400,
        onEditPressed: () => editPressed = true,
        colors: testColors,
      ),
    ));

    // Verify translated name (assuming 'food' translates to 'Food')
    expect(find.textContaining('food'), findsOneWidget);
    
    // Verify amounts are present
    expect(find.textContaining('1000'), findsNWidgets(2));
    expect(find.textContaining('400'), findsNWidgets(2));

    await tester.pumpAndSettle();
    
    // Verify the progress percentage is calculated (40%)
    expect(find.text('40%'), findsOneWidget);
  });

  testWidgets('shows "no_budget_set" state when budget is 0', (tester) async {
    await tester.pumpWidget(deps.wrap(
      BudgetCategoryCard(
        category: testCategory,
        currentBudget: 0,
        currentSpending: 50,
        onEditPressed: () {},
        colors: testColors,
      ),
    ));

    // Should find the info icon and the specific translation key/text
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.textContaining('no_budget_set'), findsOneWidget);
    
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('progress bar color changes to red when over budget (>85%)', (tester) async {
    await tester.pumpWidget(deps.wrap(
      BudgetCategoryCard(
        category: testCategory,
        currentBudget: 100,
        currentSpending: 90, // 90% is > 85%
        onEditPressed: () {},
        colors: testColors,
      ),
    ));

    // We need to pump to let the TweenAnimationBuilder finish
    await tester.pumpAndSettle();

    final LinearProgressIndicator progressIndicator = tester.widget(find.byType(LinearProgressIndicator));
    
    // Verify the color logic
    expect(progressIndicator.color, Colors.red);
  });

  testWidgets('triggers onEditPressed when card is tapped', (tester) async {
    await tester.pumpWidget(deps.wrap(
      BudgetCategoryCard(
        category: testCategory,
        currentBudget: 100,
        currentSpending: 20,
        onEditPressed: () => editPressed = true,
        colors: testColors,
      ),
    ));

    final cardInkWell = find.ancestor(
      of: find.textContaining(testCategory.name),
      matching: find.byType(InkWell),
    );

    await tester.tap(cardInkWell);
    expect(editPressed, isTrue);
  });
}