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
    final lang = context.watch<LanguageProvider>();
    final icon = CategoryIconHelper.getIcon(category.name);
    final iconColor = CategoryIconHelper.getColor(category.name, colors);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)), 
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), // Slides up from 20px
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              lang.translate(category.name),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onPrimaryContainer,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}