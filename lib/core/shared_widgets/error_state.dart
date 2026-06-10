import 'package:flutter/material.dart';
import 'package:personal_fin/core/shared_widgets/empty_state.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final String actionText;

  const ErrorState({
    super.key,
    required this.message,
    this.actionText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: message, 
      actionText: actionText,
    );
  }
}