import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/monthly_data.dart';


class MonthlyDataService {
  final FirestoreService _firestoreService = FirestoreService.instance;
  
  // Get monthly data for a specific month
  Future<MonthlyData> getMonthlyData(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    try {
      final transactions = await _firestoreService.getTransactionsInDateRange(
        firstDay,
        lastDay,
      ); 
      return _calculateMonthlyData(transactions, month);
      
    } catch (e) {
      debugPrint('Error getting monthly data: $e');
      return MonthlyData(
        month: month,
        income: 0,
        expenses: 0,
        transactionCount: 0,
      );
    }
  }
  
  // Get monthly data stream for real-time updates
  Stream<MonthlyData> streamMonthlyData(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    return _firestoreService.streamTransactionsInDateRange(firstDay, lastDay)
        .asyncMap((transactions) => _calculateMonthlyData(transactions, month));
  }
  
  // Get current month data
  Stream<MonthlyData> streamCurrentMonthData() {
    final now = DateTime.now();
    return streamMonthlyData(now);
  }
  
  // Get data for multiple months
  Future<List<MonthlyData>> getMultipleMonthsData(int numberOfMonths) async {
    final months = <MonthlyData>[];
    final now = DateTime.now();
    
    for (int i = 0; i < numberOfMonths; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final data = await getMonthlyData(month);
      months.add(data);
    }
    
    return months;
  }
  
  // Get year-to-date data
  Future<MonthlyData> getYearToDateData() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, 1, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    try {
      final transactions = await _firestoreService.getTransactionsInDateRange(
        firstDay,
        lastDay,
      );
      
      return MonthlyData(
        month: now,
        income: _calculateTotalIncome(transactions),
        expenses: _calculateTotalExpenses(transactions),
        transactionCount: transactions.length,
        categoryBreakdown: _calculateCategoryBreakdown(transactions),
      );
    } catch (e) {
      debugPrint('Error getting YTD data: $e');
      return MonthlyData(
        month: now,
        income: 0,
        expenses: 0,
        transactionCount: 0,
      );
    }
  }
  
  // Calculate monthly data from transactions
  MonthlyData _calculateMonthlyData(List<Transaction> transactions, DateTime month) {
    double income = 0;
    double expenses = 0;
    final categoryBreakdown = <String, double>{};
    
    for (var transaction in transactions) {
      if (transaction.type == 'Income') {
        income += transaction.amount;
      } else {
        expenses += transaction.amount;
        
        // Add to category breakdown
        final categoryId = transaction.categoryId;
        final categoryName = _firestoreService.getCategoryNameSync(categoryId); 
        if (categoryName.isNotEmpty) {
          categoryBreakdown.update(
            categoryName,
            (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount,
          );
        }
      }
    }
    
    return MonthlyData(
      month: month,
      income: income,
      expenses: expenses,
      transactionCount: transactions.length,
      categoryBreakdown: categoryBreakdown,
    );
  }
  
  double _calculateTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == 'Income')
        .map((t) => t.amount)
        .fold(0.0, (sum, amount) => sum + amount);
  }
  
  double _calculateTotalExpenses(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type != 'Income')
        .map((t) => t.amount)
        .fold(0.0, (sum, amount) => sum + amount);
  }
  
  Map<String, double> _calculateCategoryBreakdown(List<Transaction> transactions) {
    final breakdown = <String, double>{};
    
    for (var transaction in transactions.where((t) => t.type != 'Income')) {
      final categoryName = _firestoreService.getCategoryNameSync(transaction.categoryId);
      if (categoryName.isNotEmpty) {
        breakdown.update(
          categoryName,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    
    return breakdown;
  }
  
}