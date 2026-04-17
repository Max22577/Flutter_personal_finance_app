import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:personal_fin/core/services/auth_service.dart';
import 'package:personal_fin/core/services/profile_service.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';

class MockAuthService extends Mock implements AuthService {}
class MockProfileService extends Mock implements ProfileService {}
class MockUser extends Mock implements User {}

void main() {
  late ProfileViewModel viewModel;
  late MockAuthService mockAuth;
  late MockProfileService mockProfile;
  late MockUser mockUser;
  
  setUp(() {
    mockAuth = MockAuthService();
    mockProfile = MockProfileService();
    mockUser = MockUser();

    // Standard User Stubs
    when(() => mockUser.uid).thenReturn('user_123');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.displayName).thenReturn('Original Name');
    when(() => mockUser.photoURL).thenReturn('https://photo.com/1');

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    
    // Stub the stream to return an empty stream by default to prevent init hanging
    when(() => mockProfile.getProfileStream(any()))
        .thenAnswer((_) => const Stream.empty());
  });

  /// Helper to initialize the VM after stubs are set
  void initViewModel() {
    viewModel = ProfileViewModel(
      authService: mockAuth,
      profileService: mockProfile,
    );
  }

  group('Initialization', () {
    test('fetches user info and listens to profile stream on init', () async {
      // Setup a fake database
      final fakeDb = FakeFirebaseFirestore();
      final userId = 'user_123';
      
      // Seed the data your ViewModel expects
      // This creates a REAL DocumentSnapshot internally
      await fakeDb.collection('artifacts').doc('default-app-id')
          .collection('users').doc(userId)
          .collection('profile_data').doc('details_doc')
          .set({
            'fullName': 'John Doe',
            'bio': 'Flutter dev'
          });

      when(() => mockAuth.currentUser).thenReturn(mockUser);

      // Setup your ProfileService with the fake DB
      final profileService = ProfileService(db: fakeDb);
      
      final vm = ProfileViewModel(
        authService: mockAuth,
        profileService: profileService,
      );
      
      int attempts = 0;
      while (vm.fullName == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 10));
        attempts++;
      }

      expect(vm.fullName, 'John Doe');
      expect(vm.bio, 'Flutter dev');
      expect(vm.isLoading, false);
      
    });

    test('sets loading false if no user is found', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      
      initViewModel();

      expect(viewModel.isLoading, false);
      expect(viewModel.authEmail, 'Loading...');
    });
  });

  group('Update Profile', () {
    test('successfully updates both Firestore and Auth Profile', () async {
      when(() => mockProfile.updateProfileData(any(), any()))
          .thenAnswer((_) async => {});
      when(() => mockAuth.updateDisplayName(any()))
          .thenAnswer((_) async => {});
      
      initViewModel();

      await viewModel.updateProfile(name: 'New Name', newBio: 'New Bio');

      // Verify Service Orchestration
      verify(() => mockProfile.updateProfileData('user_123', {
        'fullName': 'New Name',
        'bio': 'New Bio',
      })).called(1);

      verify(() => mockAuth.updateDisplayName('New Name')).called(1);
      
      expect(viewModel.fullName, 'New Name');
      expect(viewModel.bio, 'New Bio');
      expect(viewModel.isLoading, false);
    });
  });

  group('Sign Out', () {
    test('calls signOut on AuthService', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});
      
      initViewModel();
      await viewModel.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });
}