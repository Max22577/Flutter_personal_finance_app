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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle, 
              ),
              child: Icon(
                icon, 
                color: iconColor, 
                size: textScaler.scale(20).clamp(18, 24),
              ),
            ),

            const SizedBox(height: 12),

            // Value Display
            // FittedBox ensures the number never breaks the card width
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toInt().toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Adaptive Label
            // We use a fixed number of lines to keep card heights consistent in a grid
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: textScaler.scale(12).clamp(10, 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}