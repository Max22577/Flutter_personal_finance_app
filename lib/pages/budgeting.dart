import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/widgets/budgeting/budget_category_card.dart';
import 'package:personal_fin/core/widgets/budgeting/budget_edit_dialog.dart';
import 'package:personal_fin/core/widgets/budgeting/month_picker.dart';
import 'package:personal_fin/core/widgets/budgeting/month_selector.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:personal_fin/core/widgets/shared/empty_state.dart';
import 'package:personal_fin/core/widgets/shared/loading_state.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';
import 'package:personal_fin/pages/category.dart';
import 'package:provider/provider.dart';
import '../core/services/firestore_service.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/transaction.dart';


class BudgetingPage extends StatefulWidget {
  const BudgetingPage({super.key});

  @override
  State<BudgetingPage> createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage> {
  final _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  late NavigationProvider _navigationProvider;
 
  String get _monthYearString => DateFormat('MMMM yyyy').format(_selectedDate);

  void _handleMonthSelection() async {
    final date = await MonthPickerSheet.show(context, _selectedDate);
    if (date != null && date != _selectedDate) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAppBar(context);
    });
    super.initState(); 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigationProvider = context.read<NavigationProvider>();
    _navigationProvider.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (!mounted) return;
    final nav = context.read<NavigationProvider>();
    
    if (nav.selectedIndex == 2 && nav.currentActions.isEmpty) {
      _updateAppBar(context);
    } 
  }

  void _updateAppBar(BuildContext context) {
      if (!mounted) return;
      final nav = context.read<NavigationProvider>();
      
      if (nav.selectedIndex == 2) {
        nav.setActions([
          IconButton(
            key: const ValueKey('budget_cat_add'), 
            icon: const Icon(Icons.category),
            onPressed: () => _addCategory(context),
          ),
        ]);
      }
  }

  void _addCategory(BuildContext context) async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(builder: (context) => const CategoryManagementPage()),
    );
    if (!mounted) return;
    setState(() {}); // Refresh to show new category 
    
  }

  
  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final nav = context.read<NavigationProvider>();

        nav.setActions([]);
      }
    });
    _navigationProvider.removeListener(_onNavChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Selector
                    _buildMonthSelector(context),
                    const SizedBox(height: 16),
                    // Stats Overview
                    _buildStatsOverview(context),
                    const SizedBox(height: 20),
                    // Categories Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget Categories',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Chip(
                            label: StreamBuilder<List<Category>>(
                              stream: FirestoreService.instance.streamCategories(),
                              builder: (context, snapshot) {
                                final count = snapshot.data
                                    ?.where((c) => !_isIncomeCategory(c.name))
                                    .length ??
                                    0;
                                return Text('$count categories');
                              },
                            ),
                            backgroundColor: colors.surface,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
            _buildBudgetList(context),
            SliverToBoxAdapter(
              child: const SizedBox(height: 140), 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return MonthSelectorCard(
      selectedDate: _selectedDate,
      onTap: _handleMonthSelection,
    );
  }

  Widget _buildStatsOverview(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final activeMonthYear = _monthYearString;

    return StreamBuilder<List<Budget>>(
      stream: FirestoreService.instance.streamBudgets(monthYear: activeMonthYear),
      builder: (context, budgetSnapshot) {
        if (!budgetSnapshot.hasData) {
          return Container(
            height: 80,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        final budgets = budgetSnapshot.data ?? [];
        final totalBudget = budgets.fold(0.0, (sum, budget) => sum + budget.amount);
        final activeBudgets = budgets.where((b) => b.amount > 0).length;

        return Container(
          key: ValueKey('stats_$activeMonthYear'),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.surfaceContainerHigh,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                imagePath: 'assets/images/undraw_wallet_diag.png',
                label: 'Total Budget',
                value: totalBudget,
                color: colors.primaryContainer,
                theme: theme,
                index: 0, // Add index
              ),        
              _buildStatItem(
                imagePath: 'assets/images/check.png',
                label: 'Active',
                value: activeBudgets.toDouble(),
                color: colors.primaryContainer,
                theme: theme,
                isCurrency: false,
                index: 1, // Add index
              ),
              _buildStatItem(
                imagePath: 'assets/images/choice.png',
                label: 'Categories',
                value: budgets.length.toDouble(),
                color: colors.primaryContainer,
                theme: theme,
                isCurrency: false,
                index: 2, // Add index
              ),
            ],
          ),   
        );
      },
    );
  }

  Widget _buildStatItem({
    required String imagePath, 
    required String label,
    required double value,
    required Color color,
    required ThemeData theme,
    required int index,
    bool isCurrency = true,
    
  }) {
    final illustrationTheme = Theme.of(context).extension<IllustrationTheme>();
    
    return TweenAnimationBuilder<double>(
      key: ValueKey('stat_item_$index'),
      // Start at -0.2 to give it a little "extra" bounce room
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 50)), 
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        // Calculate a local value that respects the delay
        // This ensures the widget stays invisible until its turn
        final staggeredValue = ((animValue - (index * 0.15)) / (1 - (index * 0.15))).clamp(0.0, 1.0);

        return Opacity(
          opacity: staggeredValue,
          child: Transform.scale(
            scale: staggeredValue,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              imagePath,
              width: 50,
              height: 50,
              color: illustrationTheme?.tintColor,
              colorBlendMode: illustrationTheme?.blendMode, 
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Value Text
          isCurrency
              ? CurrencyDisplay(
                  amount: value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  compact: true,
                )
              : Text(
                  value.toInt().toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
          const SizedBox(height: 2),
          
          // Label
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(BuildContext context) {
    final firestoreService = FirestoreService.instance;
    final currentMonthYear = _monthYearString;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return StreamBuilder<List<Budget>>(
      stream: firestoreService.streamBudgets(monthYear: currentMonthYear),
      builder: (context, budgetSnapshot) {
        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: LoadingState());
        }

        if (budgetSnapshot.hasError) {
          return SliverFillRemaining(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Error Loading Budgets',
              message: 'Please try again later',
              actionText: 'Retry',
              onAction: () => setState(() {}),
            ),
          );
        }

        return StreamBuilder<List<Category>>(
          stream: firestoreService.streamCategories(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(child: LoadingState());
            }

            if (categorySnapshot.hasError) {
              return SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Categories',
                  message: 'Please try again later',
                  actionText: 'Retry',
                  onAction: () => setState(() {}),
                ),
              );
            }

            final categories = categorySnapshot.data ?? [];

            if (categories.isEmpty) {
              return SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.category,
                  title: 'No Categories',
                  message: 'Add categories to start budgeting',
                  actionText: 'Add Category',
                  onAction: () {
                    // Navigate to category management
                  },
                ),
              );
            }

            return StreamBuilder<List<Transaction>>(
              stream: firestoreService.streamMonthlyTransactions(monthYear: currentMonthYear),
              builder: (context, transactionSnapshot) {
                final budgets = budgetSnapshot.data ?? [];
                final categories = categorySnapshot.data ?? [];
                final transactions = transactionSnapshot.data ?? [];

                // 1. Identify which category IDs are associated with "Income"
                final incomeCategoryIds = transactions
                    .where((t) => t.type == 'Income')
                    .map((t) => t.categoryId)
                    .toSet();

                // 2. Filter categories: Keep only those that AREN'T in the income set
                final filteredCategories = categories.where((category) {
                  return !incomeCategoryIds.contains(category.id);
                }).toList();

                if (filteredCategories.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.category,
                      title: 'No Categories',
                      message: 'Add categories to start budgeting',
                      actionText: 'Add Category',
                      onAction: () {
                        // Navigate to category management
                      },
                    ),
                  );
                }

                final budgetMap = {for (var b in budgets) b.categoryId: b.amount};

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = filteredCategories[index];
                      final currentBudget = budgetMap[category.id] ?? 0.0;
                      
                      // 3. Calculate spending only for 'Expense' types 
                      // (prevents accidental income subtraction if a category has both)
                      final categorySpending = transactions
                          .where((t) => t.categoryId == category.id && t.type == 'Expense')
                          .fold(0.0, (sum, t) => sum + t.amount);

                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: BudgetCategoryCard(
                            category: category,
                            currentBudget: currentBudget,
                            currentSpending: categorySpending,
                            colors: Theme.of(context).colorScheme,
                            onEditPressed: () => _showEditBudgetDialog(
                              context,
                              category,
                              currentBudget,
                              currentMonthYear,
                            ),
                          ),
                        )
                      );
                    },
                    childCount: filteredCategories.length,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

 

  void _showEditBudgetDialog(
    BuildContext context,
    Category category,
    double currentBudget,
    String monthYear,
  ) {
    showDialog(
      context: context,
      builder: (context) => BudgetEditDialog(
        category: category,
        currentBudget: currentBudget,
        monthYear: monthYear,
        onSave: (categoryId, amount, monthYear) =>
            FirestoreService.instance.setBudget(
          categoryId: categoryId,
          amount: amount,
          monthYear: monthYear,
        ),
      ),
    );
  }

  bool _isIncomeCategory(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    return lowerName.contains('income') ||
        lowerName.contains('salary') ||
        lowerName.contains('revenue');
  }
}