import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppFeedback {
  static void show(
    ScaffoldMessengerState messenger,
    String message, {
    required ColorScheme colors,    
    required TextTheme textTheme,   
    double? bottomMargin,           
    bool isError = false,
    SnackBarAction? action,
  }) {
    if (isError) {
      HapticFeedback.lightImpact();
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? colors.onErrorContainer : colors.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: isError ? colors.onErrorContainer : colors.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? colors.errorContainer : colors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: bottomMargin ?? 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: Duration(seconds: isError ? 4 : 2),
        action: action,
      ),
    );
  }
}