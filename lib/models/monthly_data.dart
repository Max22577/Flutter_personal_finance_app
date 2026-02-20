import 'package:intl/intl.dart';

class MonthlyData {
  final DateTime month;
  final double income;
  final double expenses;
  final double savingsGoal;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;

  const MonthlyData({
    required this.month,
    required this.income,
    required this.expenses,
    this.savingsGoal = 0,
    this.transactionCount = 0,
    this.categoryBreakdown = const {},
  });

  double get net => income - expenses;
  double get savingsRate => income > 0 ? (net / income * 100) : 0;
  bool get metSavingsGoal => savingsGoal > 0 ? net >= savingsGoal : false;
  
  String get formattedMonth => DateFormat('MMMM yyyy').format(month);
  String get shortMonth => DateFormat('MMM yyyy').format(month);
  
  // Calculate percentage change from another month
  double percentageChangeFrom(MonthlyData previous) {
    if (previous.net == 0) return net > 0 ? 100 : 0;
    return ((net - previous.net) / previous.net.abs() * 100);
  }
  
  // Get top spending category
  String get topCategory {
    if (categoryBreakdown.isEmpty) return 'None';
    final entry = categoryBreakdown.entries.reduce(
      (a, b) => a.value > b.value ? a : b
    );
    return entry.key;
  }
  
  // Get category breakdown percentage
  double categoryPercentage(String category) {
    if (expenses == 0) return 0;
    return (categoryBreakdown[category] ?? 0) / expenses * 100;
  }
  
  MonthlyData copyWith({
    DateTime? month,
    double? income,
    double? expenses,
    double? savingsGoal,
    int? transactionCount,
    Map<String, double>? categoryBreakdown,
  }) {
    return MonthlyData(
      month: month ?? this.month,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      transactionCount: transactionCount ?? this.transactionCount,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
    );
  }
  
  @override
  String toString() {
    return 'MonthlyData(month: $formattedMonth, income: \$$income, expenses: \$$expenses, net: \$$net)';
  }
}