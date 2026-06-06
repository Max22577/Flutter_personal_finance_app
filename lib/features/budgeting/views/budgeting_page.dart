import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/features/budgeting/views/widgets/budget_category_card.dart';
import 'package:personal_fin/features/budgeting/views/widgets/budget_edit_dialog.dart';
import 'package:personal_fin/features/budgeting/views/widgets/month_picker.dart';
import 'package:personal_fin/features/budgeting/views/widgets/month_selector.dart';
import 'package:personal_fin/core/shared_widgets/empty_state.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:personal_fin/features/budgeting/views/widgets/small_stat_card.dart';
import 'package:personal_fin/models/state_models/budgeting_state.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../view_models/budgeting_view_model.dart';
import 'widgets/main_budget_stat.dart';

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
  final ScrollController _scrollController = ScrollController();

   @override
    void initState() {
      super.initState();
      _updateAppBar();
    }

  void _updateAppBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NavigationProvider>().setActions(2, [
          _CategoryActionButton(onPressed: () => Navigator.pushNamed(context, '/categories')),
        ]);
      }
    }); 
  }

  @override
  void dispose() {
    _scrollController.dispose(); 
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetingViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStatefulBody(vm),
      ),
    );
  }

  Widget _buildStatefulBody(BudgetingViewModel vm) {
  final lang = context.read<LanguageProvider>();

  return StreamBuilder<BudgetingState>(
    stream: vm.stateStream, 
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _FullPageError(
          message: snapshot.error.toString(),
          onRetry: () => vm.setDate(vm.selectedDate), 
          lang: lang,
        );
      }

      if (!snapshot.hasData) {
        return const Center(child: LoadingState());
      }

      final state = snapshot.data!;

      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _BudgetingHeader(vm: vm, state: state),

          _BudgetListSection(state: state, vm: vm),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      );      
    },
  );
}
}
class _BudgetingHeader extends StatelessWidget {
  final BudgetingViewModel vm;
  final BudgetingState state;

  const _BudgetingHeader({required this.vm, required this.state});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            MonthSelectorCard(
              selectedDate: vm.selectedDate,
              onTap: () async {
                final date = await MonthPickerSheet.show(context, vm.selectedDate);
                if (date != null) vm.setDate(date);
              },
            ),
            const SizedBox(height: 16),
            MainBudgetStat(
              label: lang.translate('total_budget'),
              amount: state.totalBudget,
            ),
            const SizedBox(height: 16),
            _SecondaryStatsRow(state: state, lang: lang),
          ],
        ),
      ),
    );
  }
}

class _SecondaryStatsRow extends StatelessWidget {
  final BudgetingState state;
  final LanguageProvider lang;

  const _SecondaryStatsRow({required this.state, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SmallStatCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.blue,
            label: lang.translate('active'),
            value: state.activeBudgetsCount.toDouble(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SmallStatCard(
            icon: Icons.category_outlined,
            iconColor: Colors.orange,
            label: lang.translate('categories_count'),
            value: state.totalCategoryCount.toDouble(),
          ),
        ),
      ],
    );
  }
}

class _BudgetListSection extends StatelessWidget {
  final BudgetingState state;
  final BudgetingViewModel vm;

  const _BudgetListSection({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final currencyProvider = context.read<CurrencyProvider>();
    final code = currencyProvider.currency.code;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return MultiSliver( 
      children: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              lang.translate('categories').toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final category = state.categories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: BudgetCategoryCard(
                  colors: colors,
                  category: category,
                  currentBudget: state.budgetMap[category.id] ?? 0.0,
                  currentSpending: state.spendingMap[category.id] ?? 0.0,
                  onEditPressed: () => _openEdit(context, category, state, code),
                ),
              );
            },
            childCount: state.categories.length,
          ),
        ),
      ],
    );
  }

  void _openEdit(BuildContext context, dynamic category, BudgetingState state, String currencyCode) {
    showDialog(
      context: context,
      builder: (context) => BudgetEditDialog(
        category: category,
        currentBudget: state.budgetMap[category.id] ?? 0.0,
        selectedDate: state.selectedDate,
        onSave: (id, newAmount, _) => vm.setBudget(id, newAmount, currencyCode),
      ),
    );
  }
}

class _CategoryActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CategoryActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: const Icon(Icons.category),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _FullPageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final LanguageProvider lang;

  const _FullPageError({required this.message, required this.onRetry, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.error_outline,
        title: lang.translate('error_loading_budgets'),
        message: message,
        actionText: lang.translate('retry'),
        onAction: onRetry,
      ),
    );
  }
}