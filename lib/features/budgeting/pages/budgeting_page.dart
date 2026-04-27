import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/features/budgeting/widgets/budget_category_card.dart';
import 'package:personal_fin/features/budgeting/widgets/budget_edit_dialog.dart';
import 'package:personal_fin/features/budgeting/widgets/month_picker.dart';
import 'package:personal_fin/features/budgeting/widgets/month_selector.dart';
import 'package:personal_fin/core/widgets/empty_state.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:personal_fin/features/budgeting/widgets/small_stat_card.dart';
import 'package:personal_fin/features/category/pages/category_management_page.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../view_models/budgeting_view_model.dart';
import '../widgets/main_budget_stat.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navProvider = context.read<NavigationProvider>();
    _navProvider.addListener(_onNavChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
      _onNavChanged(); 
    });
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
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.category),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              shape: const CircleBorder(),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementPage())),
          ),
        ),
      ]);
    }
     
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navProvider.setActions([]);
  
    });
    _navProvider.removeListener(_onNavChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetingViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildMainContent(vm, lang, textTheme, colors),
      ),
    );
  }

  Widget _buildMainContent(BudgetingViewModel vm, LanguageProvider lang, TextTheme textTheme, ColorScheme colors) {
    // Error State
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

    // Loading State
    // Since currentState is null until the first stream emission
    final state = vm.currentState;
    if (state == null) {
      return const Center(child: LoadingState());
    }

    return RefreshIndicator(
      onRefresh: () async => await vm.refreshData(), 
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                lang.translate('categories').toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: colors.outline,
                ),
              ),
            ),
          ),
          _buildBudgetList(context, state),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, BudgetingState state) {
    final lang = context.watch<LanguageProvider>();
    final totalBudget = state.totalBudget;
    final activeBudgets = state.activeBudgetsCount;
    final categoryCount = state.totalCategoryCount;

    return Column(
      children: [
        /// MAIN STAT (TOTAL BUDGET)
        MainBudgetStat(
          label: lang.translate('total_budget'),
          amount: totalBudget,
        ),
        const SizedBox(height: 16),
        /// SECONDARY STATS
        Row(
          children: [
            Expanded(
              child: SmallStatCard(
                icon: Icons.check_circle_outline,
                iconColor: Colors.blue,
                label: lang.translate('active'),
                value: activeBudgets.toDouble(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: SmallStatCard(
                icon: Icons.category_outlined,
                iconColor: Colors.orange,
                label: lang.translate('categories_count'),
                value: categoryCount.toDouble(),
              ),
            ),
          ],
        ),
      ],
    );   
  }

  
  Widget _buildBudgetList(BuildContext context, BudgetingState state) {
    final vm = context.read<BudgetingViewModel>();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final category = state.categories[index];
        final currentBudget = state.budgetMap[category.id] ?? 0.0;
        final spending = state.spendingMap[category.id] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        onSave: (id, newAmount, month) => vm.updateBudget(id, newAmount),
      ),
    );
  }

}



