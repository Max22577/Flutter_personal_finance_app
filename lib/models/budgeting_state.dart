import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';

class BudgetingState {
  final List<Category> categories;
  final Map<String, double> budgetMap;
  final Map<String, double> spendingMap;
  final List<Transaction> transactions;
  final double totalBudget;
  final int activeBudgetsCount;
  final int totalCategoryCount;
  final String monthYear;

  BudgetingState({
    required this.categories,
    required this.budgetMap,
    required this.spendingMap,
    required this.transactions,
    required this.totalBudget,
    required this.activeBudgetsCount,
    required this.monthYear,
    required this.totalCategoryCount,
  });
}