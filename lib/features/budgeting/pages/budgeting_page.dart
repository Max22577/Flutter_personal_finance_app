import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/features/budgeting/widgets/budget_category_card.dart';
import 'package:personal_fin/features/budgeting/widgets/budget_edit_dialog.dart';
import 'package:personal_fin/features/budgeting/widgets/month_picker.dart';
import 'package:personal_fin/features/budgeting/widgets/month_selector.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:personal_fin/core/widgets/shared/empty_state.dart';
import 'package:personal_fin/core/widgets/shared/loading_state.dart';
import 'package:personal_fin/features/category/pages/category_management_page.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../view_models/budgeting_view_model.dart';

class BudgetingPage extends StatelessWidget {
  const BudgetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BudgetingViewContent();
  }
}

class BudgetingViewContent extends StatefulWidget {
  const BudgetingViewContent({super.key});

  @override
  State<BudgetingViewContent> createState() => _BudgetingViewContentState();
}

class _BudgetingViewContentState extends State<BudgetingViewContent> {
  late NavigationProvider _navProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navProvider = context.read<NavigationProvider>();
    _navProvider.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (!mounted) return;
    
    if (_navProvider.selectedIndex == 2 && _navProvider.currentActions.isEmpty) {
      _updateAppBar();
    }
  }

  void _updateAppBar() {
    if (!mounted) return;
    if (_navProvider.selectedIndex == 2) {
      _navProvider.setActions([
        IconButton(
          icon: const Icon(Icons.category),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementPage())),
        ),
      ]);
    }
     
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _navProvider.setActions([]);
      }
    });
    _navProvider.removeListener(_onNavChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetingViewModel>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      body: _buildBody(vm, lang),
    );
  }

  Widget _buildBody(BudgetingViewModel vm, LanguageProvider lang) {
    // 1. Handle Error State
    if (vm.errorMessage != null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: lang.translate('error_loading_budgets'),
          message: vm.errorMessage!,
          actionText: lang.translate('retry'),
          onAction: () => vm.retry(), 
        ),
      );
    }

    // 2. Handle Loading State
    // Since currentState is null until the first stream emission
    final state = vm.currentState;
    if (state == null) {
      return const Center(child: LoadingState());
    }

    // 3. Main Content
    return RefreshIndicator(
      onRefresh: () async => await vm.refreshData(), 
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  MonthSelectorCard(
                    selectedDate: vm.selectedDate,
                    onTap: () async {
                      final date = await MonthPickerSheet.show(context, vm.selectedDate);
                      // This triggers _updateRepos inside the VM automatically
                      if (date != null) vm.setDate(date); 
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStatsOverview(context, state),
                ],
              ),
            ),
          ),
          _buildBudgetList(context, state),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, BudgetingState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();
    final totalBudget = state.totalBudget;
    final activeBudgets = state.activeBudgetsCount;
    final categoryCount = state.totalCategoryCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.account_balance_wallet_rounded,
              label: lang.translate('total_budget'),
              value: totalBudget,
              isCurrency: true,
            ),
          ),
          _divider(colors),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_outline,
              label: lang.translate('active'),
              value: activeBudgets.toDouble(),
              isCurrency: false,
            ),
          ),
          _divider(colors),
          Expanded(
            child: _StatItem(
              icon: Icons.category_outlined,
              label: lang.translate('categories_count'),
              value: categoryCount.toDouble(),
              isCurrency: false,
            ),
          ),
        ],
      ),
    );   
  }

  Widget _divider(ColorScheme colors) {
    return Container(
      width: 1,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: colors.outlineVariant,
    );
  }
  
  
  Widget _buildBudgetList(BuildContext context, BudgetingState state) {
    final vm = context.read<BudgetingViewModel>();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final category = state.categories[index];
        final currentBudget = state.budgetMap[category.id] ?? 0.0;
        final spending = state.transactions
            .where((t) => t.categoryId == category.id && t.type == 'Expense')
            .fold(0.0, (sum, t) => sum + t.amount);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BudgetCategoryCard(
            colors: Theme.of(context).colorScheme,
            category: category,
            currentBudget: currentBudget,
            currentSpending: spending,
            onEditPressed: () => _showEditDialog(context, category, currentBudget, state.monthYear, vm),
          ),
        );
      }, childCount: state.categories.length),
    );
  }

  void _showEditDialog(BuildContext context, Category cat, double amount, String my, BudgetingViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => BudgetEditDialog(
        category: cat,
        currentBudget: amount,
        monthYear: my,
        onSave: (id, newAmount, month) => vm.updateBudget(id, newAmount, month),
      ),
    );
  }

}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final bool isCurrency;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      builder: (context, animatedValue, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colors.primary,
                size: 24,
              ),
            ),

            const SizedBox(height: 10),

            isCurrency
                ? CurrencyDisplay(
                    amount: animatedValue,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    compact: true,
                  )
                : Text(
                    animatedValue.toInt().toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

            const SizedBox(height: 4),

            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        );
      },
    );
  }
}