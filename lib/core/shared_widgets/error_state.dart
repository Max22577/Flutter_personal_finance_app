import 'package:flutter/material.dart';
import 'package:personal_fin/core/shared_widgets/empty_state.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String actionText;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.actionText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: message, // Pass the technical error message or a friendly string
      actionText: actionText,
      onAction: onRetry,
    );
  }
}