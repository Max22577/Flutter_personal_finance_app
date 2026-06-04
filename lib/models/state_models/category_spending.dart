import 'package:personal_fin/models/category.dart';

class CategorySpending {
  final Category category;
  final double totalAmount;
  final double percentage; 

  CategorySpending({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });
}