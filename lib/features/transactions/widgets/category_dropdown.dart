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
    final lang = context.watch<LanguageProvider>();

    return DropdownButtonFormField<Category?>(
      initialValue: selectedCategory, 
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
        ...categories.map((Category category) {
          return DropdownMenuItem<Category?>(
            value: category,
            child: Text(lang.translate(category.name)), 
          );
        }),
        
        // "Add Category" Action
        DropdownMenuItem<Category?>(
          value: null, 
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                lang.translate('add_category_action'),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
      onChanged: (Category? value) {
        if (value == null) {
          Navigator.pushNamed(context, '/categories');
        } else {
          onChanged(value);
        }
      },
      validator: (value) {
        if (value == null && categories.isEmpty) {
          return lang.translate('please_add_category_first');
        }
        if (value == null) {
          return lang.translate('select_category');
        }
        return null;
      },
    );
  }
}