import 'package:flutter/material.dart';

class CircularIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final TextScaler textScaler;
  final double baseSize;

  const CircularIconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.textScaler,
    this.baseSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: textScaler.scale(baseSize).clamp(18, 24),
      ),
    );
  }
}