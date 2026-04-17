import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeViewModel extends ChangeNotifier {
  // Use a private variable for the auth instance
  final FirebaseAuth _auth;

  // Constructor accepts an auth instance (defaults to real Firebase)
  HomeViewModel({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Data Getters
  User? get currentUser => _auth.currentUser;
  String get displayName => currentUser?.displayName ?? 'User Profile';
  String get email => currentUser?.email ?? 'Not Signed In';

  // Navigation Mapping 
  final Map<String, int> _mainRoutes = {
    '/dashboard': 0,
    '/transactions': 1,
    '/budgeting': 2,
    '/profile': 3,
  };

  /// Returns the index if the route is a main tab, otherwise null
  int? getTabIndex(String routeName) => _mainRoutes[routeName];

  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      debugPrint("Logout Error: $e");
      return false;
    }
  }
}