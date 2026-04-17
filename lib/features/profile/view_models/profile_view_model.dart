import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/services/auth_service.dart';
import 'package:personal_fin/core/services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService;
  final ProfileService _profileService;

  bool isLoading = true;
  String? fullName;
  String? bio;
  String? photoUrl;
  String authEmail = 'Loading...';

  StreamSubscription? _profileSubscription;

  // Constructor with Dependency Injection
  ProfileViewModel({
    AuthService? authService,
    ProfileService? profileService,
  })  : _authService = authService ?? AuthService(),
        _profileService = profileService ?? ProfileService() {
    _init();
  }

  void _init() {
    final user = _authService.currentUser;
    if (user == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    authEmail = user.email ?? 'N/A';
    photoUrl = user.photoURL;

    _profileSubscription = _profileService.getProfileStream(user.uid).listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          fullName = data['fullName'] ?? user.displayName;
          bio = data['bio'] ?? '';
        } else {
          fullName = user.displayName;
          bio = '';
        }
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateProfile({required String name, required String newBio}) async {
    final user = _authService.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      // Update Database
      await _profileService.updateProfileData(user.uid, {
        'fullName': name,
        'bio': newBio,
      });

      // Update Auth Profile
      await _authService.updateDisplayName(name);

      // Local state update
      fullName = name;
      bio = newBio;
    } catch (e) {
      debugPrint("Update failed: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}