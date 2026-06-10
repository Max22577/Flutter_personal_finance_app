import 'package:flutter/material.dart';

/// The ultimate blueprint for all errors within the application.
class AppException implements Exception {
  final String message;          // Technical details for internal logging
  final String code;             // Domain-specific error code (e.g., 'auth/user-not-found')
  final dynamic originalError;   // Catch-all bucket for the native object (FirebaseException, SocketException, etc.)
  final StackTrace? stackTrace;  // Crucial for developer debugging

  AppException({
    required this.message,
    this.code = 'unknown',
    this.originalError,
    this.stackTrace,
  });

  /// Map the technical error code to a user-friendly, localized translation key.
  String toUserMessage(BuildContext context) {
    // If you use a LanguageProvider or generic localization:
    // final lang = context.read<LanguageProvider>();
    
    switch (code) {
      case 'network-timeout':
      case 'no-internet':
        return "Connection lost. Please check your internet and try again.";
      case 'permission-denied':
        return "You don't have permission to modify this data.";
      case 'insufficient-funds':
        return "Transaction failed: Your account balance is too low.";
      case 'unauthenticated':
        return "Your session has expired. Please log in again.";
      default:
        return "Something went wrong on our end. Please try again later.";
    }
  }

  /// Map the error to a relevant icon to give visual context in Error State Widgets.
  IconData get toIcon {
    switch (code) {
      case 'network-timeout':
      case 'no-internet':
        return Icons.wifi_off_rounded;
      case 'insufficient-funds':
        return Icons.account_balance_wallet_rounded;
      case 'permission-denied':
        return Icons.gpp_bad_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  factory AppException.fromFirebase(dynamic e, [StackTrace? stack]) {
    String code = 'auth-error';
    String message = e.toString();

    if (e.writeError != null) {
      // Handle specific Firestore batch/write errors
      if (e.writeError.code == 7) code = 'permission-denied';
    } else if (e.code != null) {
      // Standard FirebaseException matching codes
      code = e.code;
      message = e.message ?? message;
    }

    return AppException(
      message: message,
      code: code,
      originalError: e,
      stackTrace: stack ?? StackTrace.current,
    );
  }

  factory AppException.fromNetwork(dynamic e, [StackTrace? stack]) {
    return AppException(
      message: "Network request failed: ${e.toString()}",
      code: 'no-internet',
      originalError: e,
      stackTrace: stack ?? StackTrace.current,
    );
  }

  @override
  String toString() => 'AppException[code: $code]: $message';
}