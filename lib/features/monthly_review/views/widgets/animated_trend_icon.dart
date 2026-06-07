import 'package:flutter/material.dart';

class AnimatedTrendIcon extends StatelessWidget {
  final String monthId;
  final bool isPositive;
  final Color trendColor;

  const AnimatedTrendIcon({
    super.key,
    required this.monthId,
    required this.isPositive,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return TweenAnimationBuilder<double>(
      key: ValueKey('${monthId}_$isPositive'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: trendColor,
              size: textScaler.scale(20),
            ),
          ),
        );
      },
    );
  }
}