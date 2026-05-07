import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';

class CategoryDropdown extends StatelessWidget {
  final Category? selectedCategory;
  final List<Category> categories;
  final ValueChanged<Category?> onChanged;

  const CategoryDropdown({
    required this.selectedCategory,
    required this.categories,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();

    return DropdownButtonFormField<Category?>(
      initialValue: selectedCategory, 
      isExpanded: true,
      decoration: InputDecoration(
        labelText: lang.translate('category'),
        prefixIcon: Icon(Icons.category, color: colors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
      ),
      dropdownColor: colors.surface,
      items: [
        // Map existing categories 
        ...categories.map((category) => DropdownMenuItem<Category?>(
              value: category,
              child: _CategoryItem(category: category, textTheme: textTheme, lang: lang),
            )),

        // Add Category Action 
        DropdownMenuItem<Category?>(
          value: null,
          child: _AddCategoryAction(colors: colors, textTheme: textTheme, lang: lang),
        ),
      ],
      onChanged: (Category? value) {
        if (value == null) {
          Navigator.pushNamed(context, '/categories');
        } else {
          onChanged(value);
        }
      },
      validator: (value) => _validate(value, categories, lang),
    );
  }

  String? _validate(Category? value, List<Category> categories, LanguageProvider lang) {
    if (value == null && categories.isEmpty) {
      return lang.translate('please_add_category_first');
    }
    return value == null ? lang.translate('select_category') : null;
  }
}

class _CategoryItem extends StatelessWidget {
  final Category category;
  final TextTheme textTheme;
  final LanguageProvider lang;

  const _CategoryItem({
    required this.category,
    required this.textTheme,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      lang.translate(category.name),
      style: textTheme.bodyMedium,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _AddCategoryAction extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final LanguageProvider lang;

  const _AddCategoryAction({
    required this.colors,
    required this.textTheme,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    
    return Row(
      children: [
        Icon(
          Icons.add_circle_outline,
          size: textScaler.scale(20).clamp(20, 28),
          color: colors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lang.translate('add_category_action'),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}