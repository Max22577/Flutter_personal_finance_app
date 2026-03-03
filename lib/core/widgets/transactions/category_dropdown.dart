import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'transaction_form.dart';

class CategoryDropdown extends StatelessWidget {
  final DropdownItem? selectedCategory;
  final List<DropdownItem> categories;
  final ValueChanged<DropdownItem?> onChanged;

  const CategoryDropdown({
    required this.selectedCategory,
    required this.categories,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();

    return DropdownButtonFormField<DropdownItem>(
      initialValue: selectedCategory, 
      decoration: InputDecoration(
        labelText: lang.translate('category'),
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: [
        ...categories.map((DropdownItem item) {
          return DropdownMenuItem<DropdownItem>(
            value: item,
            child: Text(lang.translate(item.name)),
          );
        }),
        
        DropdownMenuItem<DropdownItem>(
          value: null, 
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                lang.translate('add_category_action'),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
      onChanged: (DropdownItem? value) {
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