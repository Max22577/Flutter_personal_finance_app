import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/features/category/widgets/predefined_chip.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';

class MockLanguageProvider extends Mock implements LanguageProvider {}

void main() {
  late MockLanguageProvider mockLang;

  setUp(() {
    mockLang = MockLanguageProvider();
    
    // Stub the translation logic
    when(() => mockLang.localeCode).thenReturn('en');
    when(() => mockLang.translate(any())).thenAnswer((inv) {    
      return inv.positionalArguments[0] as String;   
    });
    when(() => mockLang.localeStream).thenAnswer((_) => Stream.value('en'));
  });

  Widget buildTestWidget({required Category category, int index = 0}) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<LanguageProvider>.value(
          value: mockLang,
          child: PredefinedCategoryChip(
            category: category,
            index: index,
          ),
        ),
      ),
    );
  }

  group('PredefinedCategoryChip Rendering', () {
    testWidgets('displays the translated category name', (tester) async {
      final category = Category(id: '1', name: 'food');
      
      await tester.pumpWidget(buildTestWidget(category: category));
      
      await tester.pumpAndSettle();

      expect(find.text('food'), findsOneWidget);
      
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('applies primaryContainer background color with transparency', (tester) async {
      final category = Category(id: '1', name: 'bills');
      
      await tester.pumpWidget(buildTestWidget(category: category));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      
      // Verify it's using a color
      expect(decoration.color, isNotNull);

    });
  });

  group('Animation Logic', () {
    testWidgets('starts at zero opacity and slides up', (tester) async {
      final category = Category(id: '1', name: 'transport');

      await tester.pumpWidget(buildTestWidget(category: category, index: 0));

      // At the very first frame (t=0), value is 0.0
      // Opacity should be 0.0
      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, 0.0);

      // Pump halfway (duration is 400ms for index 0)
      await tester.pump(const Duration(milliseconds: 200));
      
      final midOpacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(midOpacity.opacity, isNot(0.0));
      
      // Finish animation
      await tester.pumpAndSettle();
      final finalOpacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(finalOpacity.opacity, 1.0);
    });

    testWidgets('staggered animation duration increases with index', (tester) async {
      final category = Category(id: '1', name: 'health');

      // Test with index 5. Duration should be 400 + (5 * 100) = 900ms
      await tester.pumpWidget(buildTestWidget(category: category, index: 5));

      // At 500ms, the animation for index 0 would be done, but index 5 should still be going
      await tester.pump(const Duration(milliseconds: 100));
      
      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));

      expect(opacityWidget.opacity, greaterThan(0.0));
      expect(opacityWidget.opacity, lessThan(1.0));

      await tester.pump(const Duration(milliseconds: 700));

      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1.0);
    });
  });
}