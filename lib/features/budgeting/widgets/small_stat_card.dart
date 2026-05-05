import 'package:flutter/material.dart';

class SmallStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double value;

  const SmallStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Adaptive Icon Badge
            CircularIconBadge(
              icon: icon,
              color: iconColor,
              textScaler: textScaler,
            ),

            const SizedBox(height: 12),

            // Scalable Value
            _StatValue(
              value: value,
              style: theme.textTheme.titleLarge,
            ),

            const SizedBox(height: 4),

            // Constrained Label
            _StatLabel(
              label: label,
              textScaler: textScaler,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  final double value;
  final TextStyle? style;

  const _StatValue({required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value.toInt().toString(),
        style: style?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _StatLabel extends StatelessWidget {
  final String label;
  final TextScaler textScaler;
  final TextStyle? style;

  const _StatLabel({
    required this.label,
    required this.textScaler,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style?.copyWith(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w500,
        fontSize: textScaler.scale(12).clamp(10, 14),
      ),
    );
  }
}

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