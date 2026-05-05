import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';

class PredefinedCategoryChip extends StatelessWidget {
  final Category category;
  final int index;
  final VoidCallback? onTap;

  const PredefinedCategoryChip({
    super.key,
    required this.category,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();
    
    final icon = CategoryIconHelper.getIcon(category);
    final iconColor = CategoryIconHelper.getColor(category, colors);

    return _AnimatedStaggerEntry(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ChipIcon(icon: icon, color: iconColor),
                  
                  const SizedBox(width: 10),
                  
                  Text(
                    lang.translate(category.name),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStaggerEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedStaggerEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ChipIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ChipIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}