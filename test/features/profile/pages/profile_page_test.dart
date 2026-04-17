import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/profile/pages/profile_page.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';
import '../../../helpers/test_nav_helpers.dart';


// Create the mock
class MockProfileViewModel extends Mock implements ProfileViewModel {}

void main() {
  late TestNavigationDependencyManager tdm;
  late MockProfileViewModel mockProfileVM;

  setUp(() {
    tdm = TestNavigationDependencyManager();
    mockProfileVM = MockProfileViewModel();

    // Default Stubs
    when(() => mockProfileVM.isLoading).thenReturn(false);
    when(() => mockProfileVM.fullName).thenReturn('Test User');
    when(() => mockProfileVM.bio).thenReturn('Hello from tests');
    when(() => mockProfileVM.authEmail).thenReturn('test@example.com');
    when(() => mockProfileVM.photoUrl).thenReturn(null);
    when(() => mockProfileVM.signOut()).thenAnswer((_) async {});
  });

  group('ProfilePage UI Tests', () {
    testWidgets('shows loading indicator when VM is loading', (tester) async {
      when(() => mockProfileVM.isLoading).thenReturn(true);

      await tester.pumpWidget(tdm.wrap(ProfilePage(viewModel: mockProfileVM)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays correct user data and populates text fields', (tester) async {
      await tester.pumpWidget(tdm.wrap(ProfilePage(viewModel: mockProfileVM)));
      await tester.pumpAndSettle();

      // Check header text
      expect(find.text('Test User'), findsNWidgets(2));
      expect(find.text('test@example.com'), findsAtLeast(1));

      // Check text field values
      expect(find.widgetWithText(TextFormField, 'Test User'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Hello from tests'), findsOneWidget);
    });

    testWidgets('calls updateProfile when save button is pressed', (tester) async {
      // Stub the update call
      when(() => mockProfileVM.updateProfile(
        name: any(named: 'name'),
        newBio: any(named: 'newBio'),
      )).thenAnswer((_) async => {});

      // Set a taller window size (e.g., iPhone 13 Pro dimensions)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      // IMPORTANT: Reset this at the end of the test or in tearDown
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(tdm.wrap(ProfilePage(viewModel: mockProfileVM)));
      await tester.pumpAndSettle();

      // Enter new text
      await tester.enterText(find.widgetWithText(TextFormField, 'Test User'), 'Updated Name');
      
      // Tap Save
      await tester.tap(find.text('save_changes'));
      await tester.pump();

      // Verify VM interaction
      verify(() => mockProfileVM.updateProfile(
        name: 'Updated Name',
        newBio: 'Hello from tests',
      )).called(1);
    });

    testWidgets('AppBar logout button triggers signOut', (tester) async {
      when(() => tdm.mockNav.selectedIndex).thenReturn(3);

      await tester.pumpWidget(tdm.wrap(ProfilePage(viewModel: mockProfileVM)));
      await tester.pumpAndSettle(); 

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();

      verify(() => mockProfileVM.signOut()).called(1);
    });
  });
}