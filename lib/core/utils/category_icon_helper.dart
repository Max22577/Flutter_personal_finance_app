import 'package:flutter/material.dart';
import 'package:personal_fin/models/category.dart';

class CategoryIconHelper {
  static IconData getIcon(Category category) {
    // custom icon first
    if (category.isCustom && category.iconCode != null) {
      return IconData(
        category.iconCode!,
        fontFamily: 'MaterialIcons',
      );
    }

    // Fallback to predefined mapping
    switch (category.id) {
      case 'cat_food':
        return Icons.restaurant;
      case 'cat_trans':
        return Icons.directions_car;
      case 'cat_rent':
        return Icons.home_rounded;
      case 'cat_savings':
        return Icons.savings_rounded;
      case 'cat_salary':
        return Icons.favorite;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'education':
        return Icons.school;
      default:
        // Return a generic icon if nothing matches
        return Icons.help_outline;
    }
  }

  static Color getColor(Category category, ColorScheme colors) {
    // 1. Check for custom color first
    if (category.isCustom && category.colorValue != null) {
      return Color(category.colorValue!);
    }

    // 2. Fallback to predefined mapping
    switch (category.id) {
      case 'cat_food':
        return Colors.orange;
      case 'cat_trans':
        return Colors.blue;
      case 'cat_rent':
        return Colors.purple;
      case 'cat_savings':
        return Colors.indigo;
      case 'cat_salary':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      default:
        // Use the app's primary color as the default fallback
        return colors.primary;
    }
  }
}