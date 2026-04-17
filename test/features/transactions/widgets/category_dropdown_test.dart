import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/features/transactions/widgets/category_dropdown.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../../../helpers/test_helpers.dart';


class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late TestDependencyManager deps;
  late List<Category> testCategories;
  late MockNavigatorObserver mockObserver;

  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  setUp(() {
    deps = TestDependencyManager();
    mockObserver = MockNavigatorObserver();
    testCategories = [
      Category(id: '1', name: 'Food'),
      Category(id: '2', name: 'Transport'),
    ];
  });

  group('CategoryDropdown Widget Tests -', () {
    testWidgets('renders selected category correctly', (tester) async {
      await tester.pumpWidget(deps.wrap(
        CategoryDropdown(
          selectedCategory: testCategories[0],
          categories: testCategories,
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('shows all categories and "Add Category" option when opened', (tester) async {
      await tester.pumpWidget(deps.wrap(
        CategoryDropdown(
          selectedCategory: null,
          categories: testCategories,
          onChanged: (_) {},
        ),
      ));

      await tester.tap(find.byType(CategoryDropdown));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      
      expect(find.text('add_category_action').last, findsOneWidget);
    });

    testWidgets('calls onChanged when a category is selected', (tester) async {
      Category? selected;
      
      await tester.pumpWidget(deps.wrap(
        CategoryDropdown(
          selectedCategory: null,
          categories: testCategories,
          onChanged: (val) => selected = val,
        ),
      ));

      await tester.tap(find.byType(CategoryDropdown));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Transport').last);
      await tester.pumpAndSettle();

      expect(selected, testCategories[1]);
    });

    testWidgets('navigates to /categories when "Add Category" is selected', (tester) async {
      // To test navigation, we need to pass the observer to MaterialApp
      // We'll wrap it manually here instead of using deps.wrap for this specific case
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LanguageProvider>.value(value: deps.mockLang),
          ],
          child: MaterialApp(
            navigatorObservers: [mockObserver],
            routes: {
              '/categories': (context) => const Scaffold(body: Text('Category Screen')),
            },
            home: Scaffold(
              body: CategoryDropdown(
                selectedCategory: null,
                categories: testCategories,
                onChanged: (_) {},
              ),
              
            ),
          ),
        )
      );

      // Open dropdown
      await tester.tap(find.byType(CategoryDropdown));
      await tester.pumpAndSettle();

      // Clear the history
      clearInteractions(mockObserver);

      // Tap 'Add Category' action
      await tester.tap(find.text('add_category_action').last);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      verify(() => mockObserver.didPush(any(), any())).called(1);
    });

    testWidgets('shows validation error when no category is selected', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(deps.wrap(
        Form(
          key: formKey,
          child: CategoryDropdown(
            selectedCategory: null,
            categories: testCategories,
            onChanged: (_) {},
          ),
        ),
      ));

      // Trigger validation
      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text('select_category'), findsOneWidget);
    });
  });
}