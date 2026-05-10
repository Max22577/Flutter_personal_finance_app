import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/widgets/animated_empty_state.dart';
import 'package:personal_fin/core/widgets/custom_appbar.dart';
import 'package:personal_fin/core/widgets/empty_state.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:personal_fin/features/savings/pages/set_goal_page.dart';
import 'package:personal_fin/features/savings/widgets/progress_chart.dart';
import 'package:personal_fin/features/savings/widgets/savings_stat_card.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';
import '../view_models/savings_view_model.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SavingsViewModel(context.read<SavingsRepository>()),
      child: const SavingsViewContent(),
    );
  }
}

class SavingsViewContent extends StatelessWidget {
  const SavingsViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);

    if (vm.isLoading) return const Scaffold(body: Center(child: LoadingState()));
    
    if (vm.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: lang.translate('failed_to_load_goals'),
            message: vm.errorMessage ?? lang.translate('unknown_error'),
            actionText: lang.translate('retry'),
            onAction: vm.retry,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: _SavingsAppBar(hasGoals: vm.goals.isNotEmpty),
      body: vm.goals.isEmpty
          ? AnimatedEmptyState(
              message: lang.translate('No data recorded').toUpperCase(),
              imagePath: 'assets/images/savings_light.svg',
              darkImagePath: 'assets/images/savings_dark.svg',
              animationType: EmptyStateAnimation.bounce,
            )
          : _SavingsList(vm: vm),
      floatingActionButton: vm.goals.isNotEmpty ? const _AddGoalFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class _SavingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool hasGoals;
  const _SavingsAppBar({required this.hasGoals});

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: 'savings_goals',
      isRootNav: false,
      actions: [
        if (hasGoals)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _NavigationHelper.addGoal(context),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SavingsList extends StatelessWidget {
  final SavingsViewModel vm;
  const _SavingsList({required this.vm});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SavingsStatCard(vm: vm),
          const SizedBox(height: 24),
          Text(
            lang.translate('your_goals'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...vm.goals.map((goal) => _GoalListItem(goal: goal)),
        ],
      ),
    );
  }
}

class _GoalListItem extends StatelessWidget {
  final SavingsGoal goal;
  const _GoalListItem({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _NavigationHelper.editGoal(context, goal),
        child: ProgressChartWidget(goal: goal),
      ),
    );
  }
}

class _AddGoalFAB extends StatelessWidget {
  const _AddGoalFAB();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return FloatingActionButton.extended(
      onPressed: () => _NavigationHelper.addGoal(context),
      heroTag: 'addGoal',
      icon: const Icon(Icons.add),
      label: Text(lang.translate('new_goal')),
    );
  }
}

// --- Logic Helpers ---

class _NavigationHelper {
  static void addGoal(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetGoalPage()));
  }

  static void editGoal(BuildContext context, SavingsGoal goal) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SetGoalPage(existingGoal: goal)));
  }
}

