import 'package:flutter/material.dart';

class CategoryIconHelper {

  static IconData getIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'cat_food':
        return Icons.restaurant;
      case 'cat_trans':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'cat_salary':
        return Icons.favorite;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  static Color getColor(String categoryName, ColorScheme colors) {
    switch (categoryName.toLowerCase()) {
      case 'cat_food':
        return Colors.orange;
      case 'cat_trans':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'entertainment':
        return Colors.redAccent;
      case 'cat_salary':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      default:
        return colors.primary;
    }
  }
}