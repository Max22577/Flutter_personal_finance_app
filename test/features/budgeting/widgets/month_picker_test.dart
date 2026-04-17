import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/budgeting/widgets/month_picker.dart';
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
    when(() => mockLang.localeStream).thenAnswer((_) => Stream.value('en'));
  });

  Widget createWidgetUnderTest(DateTime initialDate) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MonthPickerSheet.show(context, initialDate),
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    ).wrapWithProvider(mockLang);
  }

  testWidgets('renders initial year and months correctly', (tester) async {
    final initialDate = DateTime(2026, 4, 1); 
    await tester.pumpWidget(createWidgetUnderTest(initialDate));

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('April 2026'), findsOneWidget);

    // Verify months are visible (using short format 'Apr')
    expect(find.text('Apr'), findsOneWidget);
    expect(find.text('Dec'), findsOneWidget);
  });

  testWidgets('navigates to previous and next years', (tester) async {
    final initialDate = DateTime(2026, 4, 1);
    await tester.pumpWidget(createWidgetUnderTest(initialDate));
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Tap left chevron (Previous Year)
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('April 2025'), findsOneWidget);

    // Tap right chevron twice (Next Year x2)
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('April 2027'), findsOneWidget);
  });

  testWidgets('returns selected date and closes when a month is tapped', (tester) async {
    DateTime? resultDate;
    final initialDate = DateTime(2026, 4, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultDate = await MonthPickerSheet.show(context, initialDate);
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ).wrapWithProvider(mockLang),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jan'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthPickerSheet), findsNothing);
    
    // Verify the returned date is January 2026
    expect(resultDate?.month, equals(DateTime.january));
    expect(resultDate?.year, equals(2026));
  });
}

extension on Widget {
  Widget wrapWithProvider(MockLanguageProvider mockLang) {
    return ChangeNotifierProvider<LanguageProvider>.value(
      value: mockLang,
      child: this,
    );
  }
}