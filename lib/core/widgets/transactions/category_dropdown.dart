import 'package:flutter/material.dart';
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

    return DropdownButtonFormField<DropdownItem>(
      initialValue: selectedCategory, 
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: [
        ...categories.map((DropdownItem item) {
          return DropdownMenuItem<DropdownItem>(
            value: item,
            child: Text(item.name),
          );
        }),
        
        DropdownMenuItem<DropdownItem>(
          value: null, 
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Add new category',
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
          return 'Please add a category first';
        }
        if (value == null) {
          return 'Select a category';
        }
        return null;
      },
    );
  }
}