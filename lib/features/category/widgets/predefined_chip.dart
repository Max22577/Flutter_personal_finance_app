import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';

class PredefinedCategoryChip extends StatelessWidget {
  final Category category;
  final int index; 

  const PredefinedCategoryChip({
    required this.category, 
    required this.index, 
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lang = context.watch<LanguageProvider>();
    final icon = CategoryIconHelper.getIcon(category);
    final iconColor = CategoryIconHelper.getColor(category, colors);

    return TweenAnimationBuilder<double>(
      key: ValueKey('predef_${category.id}'),
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
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {}, // Handled by parent or selection logic
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                // Using surfaceContainerHigh for better contrast in light/dark mode
                color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container for a "Badge" look
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    lang.translate(category.name),
                    style: textTheme.labelLarge?.copyWith(
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