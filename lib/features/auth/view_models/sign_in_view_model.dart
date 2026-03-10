import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/services/auth_service.dart';

class SignInViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signIn(email.trim(), password.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getFriendlyErrorMessage(e);
    } catch (e) {
      return 'Login failed. Please check your connection.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signInWithGoogle() async {
    _setLoading(true);
    try {
      final user = await _auth.signInWithGoogle();
      return user != null ? null : 'Google sign-in cancelled.';
    } catch (e) {
      return 'Google Sign-In failed. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  String _getFriendlyErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'The password you entered is incorrect.';
      case 'invalid-email': return 'The email address format is invalid.';
      case 'user-disabled': return 'This account has been disabled.';
      default: return 'An unknown error occurred. Please try again.';
    }
  }
}