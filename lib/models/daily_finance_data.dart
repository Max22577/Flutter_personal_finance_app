// lib/features/dashboard/models/daily_finance_data.dart
class DailyFinanceData {
  final DateTime date;
  final double income;
  final double expenses;
  final double net; // income - expenses

  DailyFinanceData({
    required this.date,
    required this.income,
    required this.expenses,
  }) : net = income - expenses;

  // Helper to create empty day
  factory DailyFinanceData.empty(DateTime date) {
    return DailyFinanceData(date: date, income: 0, expenses: 0);
  }

  // Add values from transaction
  DailyFinanceData addTransaction(double amount, String type) {
    if (type == 'Income') {
      return DailyFinanceData(
        date: date,
        income: income + amount,
        expenses: expenses,
      );
    } else {
      return DailyFinanceData(
        date: date,
        income: income,
        expenses: expenses + amount,
      );
    }
  }
}