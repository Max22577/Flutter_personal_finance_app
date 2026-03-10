import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:rxdart/rxdart.dart'; 
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';

class BudgetingViewModel extends ChangeNotifier {
  final _firestore = FirestoreService.instance;
  final BudgetRepository _budgetRepo;
  final MonthlyTransactionRepository _txRepo;
  final CategoryRepository _catRepo;
  final LanguageProvider _langRepo ;

  StreamSubscription? _combinedSub;
  BudgetingState? currentState;
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String? errorMessage; 
  bool isLoading = true;

  // Centralized way to get the current monthYear string
  String formattedMonthYear(String locale) => DateFormat('MMMM yyyy', locale).format(_selectedDate);

  BudgetingViewModel(this._budgetRepo, this._txRepo, this._catRepo, this._langRepo) {
    _init();
  }

  void _init() {
    // 1. Tell repos to fetch initial data
    _updateRepos();

    // 2. Combine all streams into one state listener
    _combinedSub = Rx.combineLatest4(
      _catRepo.categoriesStream,
      _budgetRepo.budgetsStream,
      _txRepo.stream,
      _langRepo.localeStream,
      (categories, budgets, transactions, locale) => _calculateState(categories, budgets, transactions, locale),
    ).listen((state) {
        currentState = state;
        errorMessage = null; 
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString(); 
        isLoading = false;
        notifyListeners();
      },
    );
  }

  BudgetingState _calculateState(List<Category> categories, List<Budget> budgets, List<Transaction> transactions, String locale) {
    // 1. Filter out Income categories logic
    final incomeIds = transactions
        .where((t) => t.type == 'Income')
        .map((t) => t.categoryId)
        .toSet();

    final filteredCategories = categories.where((c) {
      final isIncome = incomeIds.contains(c.id) || 
                        ['income', 'salary', 'revenue'].any((term) => c.name.toLowerCase().contains(term));
      return !isIncome;
    }).toList();

    // 2. Map budgets for O(1) lookup
    final budgetMap = {for (var b in budgets) b.categoryId: b.amount};

    // 3. Pre-calculate totals
    final categoryCount = budgets.length;
    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.amount);
    final activeCount = budgets.where((b) => b.amount > 0).length;

    return BudgetingState(
      categories: filteredCategories,
      budgetMap: budgetMap,
      transactions: transactions,
      totalBudget: totalBudget,
      activeBudgetsCount: activeCount,
      monthYear: formattedMonthYear(locale),
      totalCategoryCount: categoryCount,
    );
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    _updateRepos(); // Repos handle the stream switch
    notifyListeners();
  }

  void _updateRepos() {
    _budgetRepo.fetchBudgets(formattedMonthYear(_langRepo.localeCode));
    _txRepo.fetchForMonth(formattedMonthYear(_langRepo.localeCode));
  }

  Future<void> updateBudget(String categoryId, double amount, String monthYear) async {
    await _firestore.setBudget(
      categoryId: categoryId,
      amount: amount,
      monthYear: monthYear,
    );
  }

  void retry() {
    errorMessage = null;
    isLoading = true;
    notifyListeners();
    _updateRepos(); 
  }

  Future<void> refreshData() async {
    await Future.wait([
      _budgetRepo.refresh(),
      _txRepo.refresh(),
      _catRepo.refresh(),
    ]);
    // No notifyListeners needed here because the 
    // streams will automatically emit new values!
  }

  @override
  void dispose() {
    _combinedSub?.cancel();
    super.dispose();
  }
}

// Data holder for the View
class BudgetingState {
  final List<Category> categories;
  final Map<String, double> budgetMap;
  final List<Transaction> transactions;
  final double totalBudget;
  final int activeBudgetsCount;
  final int totalCategoryCount;
  final String monthYear;

  BudgetingState({
    required this.categories,
    required this.budgetMap,
    required this.transactions,
    required this.totalBudget,
    required this.activeBudgetsCount,
    required this.monthYear,
    required this.totalCategoryCount,
  });
}