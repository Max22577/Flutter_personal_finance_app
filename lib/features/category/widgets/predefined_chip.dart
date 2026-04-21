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
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(width: 8),
            Text(
              lang.translate(category.name),
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5,),
            ),
          ],
        ),
      ),
    );
  }
  
}