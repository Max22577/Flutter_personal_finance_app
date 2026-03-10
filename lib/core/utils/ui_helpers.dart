import 'package:flutter/material.dart';

void showFeedback(BuildContext context, String message, {bool isError = false}) {
  final colors = Theme.of(context).colorScheme;
  
  ScaffoldMessenger.of(context).removeCurrentSnackBar(); 

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? colors.onErrorContainer : colors.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? colors.onErrorContainer : colors.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? colors.errorContainer : colors.primaryContainer,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ),
  );
}