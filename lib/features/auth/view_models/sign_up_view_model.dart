import 'package:flutter/material.dart';
import 'package:personal_fin/core/services/auth_service.dart';


class SignUpViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // 1. Client-side validation
    if (password.trim() != confirmPassword.trim()) {
      return "Passwords do not match. Please re-enter.";
    }

    if (password.length < 6) {
      return "The password is too weak. It must be at least 6 characters long.";
    }

    _setLoading(true);

    try {
      await _auth.signUp(email.trim(), password.trim());
      return null; // Success
    } catch (e) {
      return _getFriendlyErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final errStr = error.toString();
    if (errStr.contains('email-already-in-use')) {
      return 'An account already exists for that email address.';
    }
    if (errStr.contains('invalid-email')) {
      return 'The email address format is invalid.';
    }
    return 'Registration failed. Please try again later.';
  }
}