import 'package:flutter/material.dart';

class GlowingExpansionTile extends StatelessWidget {
  final int index;
  final int? currentIndex;
  final IconData icon;
  final String title;
  final List<Widget> children;
  final ValueChanged<bool> onExpansionChanged;
  final bool isLogout;

  const GlowingExpansionTile({
    super.key,
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.title,
    required this.children,
    required this.onExpansionChanged,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = index == currentIndex;
    final baseActiveColor = isLogout ? colors.error : colors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.all(isSelected ? 8.0 : 0.0),
      decoration: BoxDecoration(
        color: isSelected ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(isSelected ? 16 : 0),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: baseActiveColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<int>(index),
          onExpansionChanged: onExpansionChanged,
          initiallyExpanded: isSelected,
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? baseActiveColor.withValues(alpha: 0.12) : colors.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isSelected ? baseActiveColor : (isLogout ? colors.error.withValues(alpha: 0.7) : colors.onSurfaceVariant),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? baseActiveColor : (isLogout ? colors.error : colors.onSurface),
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}