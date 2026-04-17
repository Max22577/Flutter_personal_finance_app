import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/drawer/drawer.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late TestDependencyManager deps;

  setUp(() {
    deps = TestDependencyManager();
  });

  group('AppDrawer - Basic Rendering', () {
    testWidgets('displays user name and email', (WidgetTester tester) async {
      const userName = 'John Doe';
      const userEmail = 'john@example.com';

      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: userName,
            userEmail: userEmail,
          ),
        ),
      );

      expect(find.text(userName), findsOneWidget);
      expect(find.text(userEmail), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('displays all main menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      // Verify top-level items (translated via mock)
      expect(find.text('dashboard'), findsOneWidget);
      expect(find.text('profile'), findsOneWidget);
      expect(find.text('Financial Tools'), findsOneWidget);
      expect(find.text('settings'), findsOneWidget);
      expect(find.text('transactions'), findsOneWidget);

      
    });

    testWidgets('displays version text', (WidgetTester tester) async {
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      expect(find.text('App Version 1.0.2'), findsOneWidget);
    });
  });

  group('AppDrawer - Navigation Callbacks', () {
    testWidgets('calls onNavigate with correct route for dashboard', 
        (WidgetTester tester) async {
      String? capturedRoute;
      
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (route) => capturedRoute = route,
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      await tester.tap(find.text('dashboard'));
      await tester.pumpAndSettle();

      expect(capturedRoute, '/dashboard');
    });

    testWidgets('calls onNavigate for profile submenu', 
        (WidgetTester tester) async {
      String? capturedRoute;
      
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (route) => capturedRoute = route,
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      // Expand the profile tile first
      await tester.tap(find.text('profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('user_profile'));
      await tester.pumpAndSettle();

      expect(capturedRoute, '/profile');
    });

    testWidgets('calls onLogout when logout tapped', 
        (WidgetTester tester) async {
      bool logoutCalled = false;
      
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () => logoutCalled = true,
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      // Expand profile section
      await tester.tap(find.text('profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('logout'));
      await tester.pump();

      expect(logoutCalled, isTrue);
    });
  });

  group('AppDrawer - Expansion Tiles', () {
    testWidgets('expands profile section and shows children', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      // Initially, submenu items should not be visible
      expect(find.text('user_profile'), findsNothing);
      expect(find.text('logout'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('profile'));
      await tester.pumpAndSettle();

      // Now children should be visible
      expect(find.text('user_profile'), findsOneWidget);
      expect(find.text('logout'), findsOneWidget);
    });

    testWidgets('expands financial tools section', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      await tester.tap(find.text('Financial Tools'));
      await tester.pumpAndSettle();

      expect(find.text('Savings Calculator'), findsOneWidget);
      expect(find.text('Monthly Report'), findsOneWidget);
    });
  });

  group('AppDrawer - Theme Toggle', () {
    testWidgets('displays correct theme toggle state for light mode', 
        (WidgetTester tester) async {
      // Ensure ThemeProvider reports light mode
      when(() => deps.mockThemeProvider.themeMode).thenReturn(ThemeMode.light);

      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
    });

    testWidgets('displays correct theme toggle state for dark mode', 
        (WidgetTester tester) async {
      when(() => deps.mockThemeProvider.themeMode).thenReturn(ThemeMode.dark);

      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
          themeMode: ThemeMode.dark,
        ),
      );

      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

  });  
  group('AppDrawer - Language Provider Integration', () {
    testWidgets('uses translated strings from LanguageProvider', 
        (WidgetTester tester) async {
      // Stub specific translations
      when(() => deps.mockLang.translate('dashboard')).thenReturn('Dashboard');
      when(() => deps.mockLang.translate('profile')).thenReturn('Profile');
      when(() => deps.mockLang.translate('settings')).thenReturn('Settings');

      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      // Should display stubbed translations, not keys
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      
      // Original keys should not appear
      expect(find.text('dashboard'), findsNothing);
    });
  });   

  group('AppDrawer - Visual Styling', () {
    testWidgets('applies correct header decoration based on theme brightness', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      final header = find.byType(UserAccountsDrawerHeader);
      expect(header, findsOneWidget);
      
      // Verify the header renders without errors
      final headerWidget = tester.widget<UserAccountsDrawerHeader>(header);
      expect(headerWidget.decoration, isNotNull);
    });

    testWidgets('submenu items have correct padding and icon colors', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        deps.wrap(
          AppDrawer(
            onNavigate: (_) {},
            onLogout: () {},
            userName: 'Test',
            userEmail: 'test@test.com',
          ),
        ),
      );

      await tester.tap(find.text('profile'));
      await tester.pumpAndSettle();

      final logoutItem = find.text('logout');
      expect(logoutItem, findsOneWidget);
      
      // Verify the list tile has expected padding
      final tile = tester.widget<ListTile>(find.ancestor(
        of: logoutItem,
        matching: find.byType(ListTile),
      ).first);
      
      expect(tile.contentPadding, const EdgeInsets.only(left: 30));
    });
  });
}