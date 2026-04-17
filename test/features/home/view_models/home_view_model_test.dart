import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/features/home/view_models/home_view_model.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('HomeViewModel Unit Tests', () {
    test('HomeViewModel should return correct user data from Firebase', () async {
      // Create a fake user
      final mockUser = MockUser(
        uid: 'abc_123',
        email: 'tester@test.com',
        displayName: 'Flutter Developer',
      );

      // Create the mock auth instance with that user
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      // Inject the mock into the ViewModel
      final vm = HomeViewModel(auth: mockAuth);

      // Assert
      expect(vm.displayName, 'Flutter Developer');
      expect(vm.email, 'tester@test.com');
    });

    test('signOut should update the auth state', () async {
      final mockAuth = MockFirebaseAuth(signedIn: true);
      final vm = HomeViewModel(auth: mockAuth);

      final success = await vm.signOut();

      expect(success, true);
      expect(mockAuth.currentUser, isNull); 
    });
  });

  test('getTabIndex returns correct index for valid routes', () {
    final mockAuth = MockFirebaseAuth(signedIn: true);
    final vm = HomeViewModel(auth: mockAuth);
    
    expect(vm.getTabIndex('/dashboard'), 0);
    expect(vm.getTabIndex('/transactions'), 1);
    expect(vm.getTabIndex('/non-existent'), null);
  });
}