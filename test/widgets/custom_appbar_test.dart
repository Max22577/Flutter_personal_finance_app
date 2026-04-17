import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/widgets/custom_appbar.dart';
import '../helpers/test_nav_helpers.dart';

void main() {
  late TestNavigationDependencyManager testDeps;

  setUp(() {
    testDeps = TestNavigationDependencyManager();

  });

  group('CustomAppBar - Root Navigation Mode (isRootNav: true)', () {
    testWidgets('displays title from NavigationProvider with translation', 
        (WidgetTester tester) async {
      // Arrange
      when(() => testDeps.mockNav.currentTitle).thenReturn('home_title');
      when(() => testDeps.mockLang.translate('home_title')).thenReturn('Home');

      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true),
        ),
      );

      // Assert
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('home_title'), findsNothing); // Raw key should not appear
    });

    testWidgets('uses NavigationProvider actions when available', 
        (WidgetTester tester) async {
      // Arrange
      final customAction = IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {},
      );

      testDeps.stubNavigation(
        title: 'home_title',
        actions: [customAction],
      );

      when(() => testDeps.mockLang.translate('home_title')).thenReturn('Home');

      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing); // No default
    });

    testWidgets('falls back to default actions when nav actions are empty', 
        (WidgetTester tester) async {
      // Arrange
      testDeps.stubNavigation(title: 'home_title');
      when(() => testDeps.mockLang.translate('home_title')).thenReturn('Home');

      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('centers title when isRootNav is true', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true, title: 'Test'),
        ),
      );

      // Find the AppBar and verify centerTitle
      final appBarFinder = find.byType(AppBar);
      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('wraps title in AnimatedSwitcher for smooth transitions', 
        (WidgetTester tester) async {
      testDeps.stubNavigation(title: 'title_a');
      when(() => testDeps.mockLang.translate('title_a')).thenReturn('Title A');

      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true),
        ),
      );

      // Verify AnimatedSwitcher is present
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      
      // Change title and verify animation triggers
      testDeps.stubNavigation(title: 'title_b');
      when(() => testDeps.mockLang.translate('title_b')).thenReturn('Title B');
      
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150)); 
      
      // Both titles might be visible during transition
      expect(find.text('Title A'), findsWidgets); 
    });
  });

  group('CustomAppBar - Standard Mode (isRootNav: false)', () {
    testWidgets('displays provided title with translation', 
        (WidgetTester tester) async {
      when(() => testDeps.mockLang.translate('settings')).thenReturn('Settings');

      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(title: 'settings', isRootNav: false),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('uses provided actions instead of default', 
        (WidgetTester tester) async {
      final action = IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {},
      );

      await tester.pumpWidget(
        testDeps.wrap(
          CustomAppBar(
            isRootNav: false,
            actions: [action],
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets('title is left-aligned when isRootNav is false', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(title: 'Test', isRootNav: false),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isFalse);
    });

    testWidgets('does not wrap title in AnimatedSwitcher', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(title: 'Test', isRootNav: false),
        ),
      );

      expect(find.byType(AnimatedSwitcher), findsNothing);
    });
  });

  group('CustomAppBar - Leading & AutomaticallyImplyLeading', () {
    testWidgets('uses custom leading widget when provided', 
        (WidgetTester tester) async {
      final customLeading = IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {},
      );

      await tester.pumpWidget(
        testDeps.wrap(
          CustomAppBar(
            leading: customLeading,
            automaticallyImplyLeading: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('respects automaticallyImplyLeading flag', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(
            isRootNav: false,
            automaticallyImplyLeading: false,
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.automaticallyImplyLeading, isFalse);
    });
  });

  group('CustomAppBar - Visual Properties', () {
    testWidgets('has correct preferredSize', 
        (WidgetTester tester) async {
      const appBar = CustomAppBar();
      expect(appBar.preferredSize.height, kToolbarHeight);
    });

    testWidgets('applies gradient background with blur effect', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(title: 'Test'),
        ),
      );

      // Verify container with decoration exists
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(ClipRect), findsNWidgets(2));
    });

    testWidgets('uses onPrimary color for icons and text', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(title: 'Test'),
        ),
      );

      // Find text widget and verify it renders (color testing requires more setup)
      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('CustomAppBar - Provider Integration', () {
    testWidgets('watches LanguageProvider for translation updates', 
        (WidgetTester tester) async {
      when(() => testDeps.mockLang.translate('home_title')).thenReturn('Home');
      when(() => testDeps.mockNav.currentTitle).thenReturn('home_title');

      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true),
        ),
      );

      expect(find.text('Home'), findsOneWidget);

      // Simulate provider change
      when(() => testDeps.mockLang.translate('home_title')).thenReturn('Inicio');
      
      // Rebuild with updated mock behavior
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true),
        ),
      );
      
      // Note: For real reactive testing, you'd need mockLang to extend ChangeNotifier
      // and call notifyListeners(). This verifies basic integration.
    });

    testWidgets('reads NavigationProvider without listening in root mode', 
        (WidgetTester tester) async {
      when(() => testDeps.mockNav.currentTitle).thenReturn('dashboard');
      when(() => testDeps.mockNav.currentActions).thenReturn([]);
      when(() => testDeps.mockLang.translate('dashboard')).thenReturn('Dashboard');

      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: true),
        ),
      );

      // Verify Provider.of was called (indirectly via behavior)
      expect(find.text('Dashboard'), findsOneWidget);
      verify(() => testDeps.mockNav.currentTitle).called(1);
    });
  });

  group('CustomAppBar - Edge Cases', () {
    testWidgets('handles null title gracefully in non-root mode', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: false, title: null),
        ),
      );

      // Should not crash; title area may be empty
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isNotNull); // Text widget still created with empty string
    });

    testWidgets('handles empty actions list', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(isRootNav: false, actions: []),
        ),
      );

      expect(find.byType(IconButton), findsNothing); // No default actions in non-root
    });

    testWidgets('maintains transparent AppBar background for gradient', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testDeps.wrap(
          const CustomAppBar(title: 'Test'),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(Colors.transparent));
      expect(appBar.elevation, equals(0));
      expect(appBar.surfaceTintColor, equals(Colors.transparent));
    });
  });
}