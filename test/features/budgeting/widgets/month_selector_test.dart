import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/budgeting/widgets/month_selector.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';

class MockLanguageProvider extends Mock implements LanguageProvider {}

void main() {
  late MockLanguageProvider mockLang;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });


  setUp(() {
    mockLang = MockLanguageProvider();
    when(() => mockLang.translate(any())).thenAnswer((i) => i.positionalArguments[0]);
    when(() => mockLang.localeCode).thenReturn('en');
  });

  Widget createWidgetUnderTest({
    required DateTime selectedDate,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<LanguageProvider>.value(
          value: mockLang,
          child: MonthSelectorCard(
            selectedDate: selectedDate,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders correct date format and labels', (tester) async {
    final testDate = DateTime(2026, 5, 1); 
    
    await tester.pumpWidget(createWidgetUnderTest(selectedDate: testDate));

    expect(find.text('budget_period'), findsOneWidget);

    final expectedDateString = DateFormat('MMMM yyyy', 'en').format(testDate);
    expect(find.text(expectedDateString), findsOneWidget);
    
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('shows "this_month" badge when selectedDate is current month', (tester) async {
    final now = DateTime.now();
    
    await tester.pumpWidget(createWidgetUnderTest(selectedDate: now));

    expect(find.text('this_month'), findsOneWidget);
  });

  testWidgets('hides "this_month" badge for other months', (tester) async {
    final distantDate = DateTime.now().add(const Duration(days: 60));
    
    await tester.pumpWidget(createWidgetUnderTest(selectedDate: distantDate));

    expect(find.text('this_month'), findsNothing);
  });

  testWidgets('triggers onTap callback when pressed', (tester) async {
    bool wasTapped = false;
    
    await tester.pumpWidget(createWidgetUnderTest(
      selectedDate: DateTime.now(),
      onTap: () => wasTapped = true,
    ));

    // Tap the InkWell/Card
    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(wasTapped, isTrue);
  });
}