import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_fin/features/savings/widgets/add_to_savings_button.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
import 'package:personal_fin/features/savings/widgets/progress_chart.dart';
import 'package:personal_fin/models/savings.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late TestDependencyManager deps;

  setUp(() {
    deps = TestDependencyManager();
  });

  // dummy goal
  SavingsGoal createGoal({double current = 500, double target = 1000}) {
    return SavingsGoal(
      id: 'test_id',
      name: 'New Car',
      currentAmount: current,
      targetAmount: target,
      deadline: DateTime.now().add(const Duration(days: 365)),
    );
  }

  group('ProgressChartWidget Tests -', () {
    testWidgets('renders basic goal information correctly', (tester) async {
      final goal = createGoal(current: 2000, target: 5000); // 40% progress

      await tester.pumpWidget(deps.wrap(
        ProgressChartWidget(goal: goal),
      ));

      // Check header and goal name
      expect(find.text('goal_progress'), findsOneWidget);
      expect(find.text('NEW CAR'), findsOneWidget); // Checks .toUpperCase()
      
      // Check labels
      expect(find.text('SAVED'), findsOneWidget);
      expect(find.text('remaining'), findsOneWidget);
    });

    testWidgets('calculates and displays correct percentage', (tester) async {
      // 750 / 1000 = 75%
      final goal = createGoal(current: 750, target: 1000);

      await tester.pumpWidget(deps.wrap(
        ProgressChartWidget(goal: goal),
      ));

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('handles zero target amount gracefully (0%)', (tester) async {
      final goal = createGoal(current: 0, target: 0);

      await tester.pumpWidget(deps.wrap(
        ProgressChartWidget(goal: goal),
      ));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('clamps percentage at 100% if current exceeds target', (tester) async {
      final goal = createGoal(current: 1200, target: 1000);

      await tester.pumpWidget(deps.wrap(
        ProgressChartWidget(goal: goal),
      ));

      // Should show 100%, not 120%
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('contains required functional components', (tester) async {
      final goal = createGoal();

      await tester.pumpWidget(deps.wrap(
        ProgressChartWidget(goal: goal),
      ));

      // Verify the chart widget exists
      expect(find.byType(PieChart), findsOneWidget);
      
      // Verify the "Add to Savings" button is present
      expect(find.byType(AddToSavingsButton), findsOneWidget);
      
      // Verify CurrencyDisplays are used (should be 2: one for saved, one for remaining)
      expect(find.byType(CurrencyDisplay), findsAtLeast(2));
    });
  });
}