import 'package:flutter/material.dart';

class FooterLink extends StatelessWidget {
  final String text;
  final String actionText;
  final VoidCallback onPressed;

  const FooterLink({
    super.key,
    required this.text,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white, // Adjust based on your background
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          children: [
            TextSpan(text: "$text "),
            TextSpan(
              text: actionText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}