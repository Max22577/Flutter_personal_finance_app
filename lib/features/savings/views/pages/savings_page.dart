import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/shared_widgets/animated_empty_state.dart';
import 'package:personal_fin/core/shared_widgets/custom_appbar.dart';
import 'package:personal_fin/core/shared_widgets/empty_state.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:personal_fin/features/savings/views/pages/set_goal_page.dart';
import 'package:personal_fin/features/savings/views/widgets/progress_chart.dart';
import 'package:personal_fin/features/savings/views/widgets/savings_stat_card.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';
import '../../view_models/savings_view_model.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SavingsViewModel(
        context.read<SavingsRepository>(),
        context.read<ExchangeRateService>(),
        context.read<CurrencyProvider>()
      ),
      child: const SavingsViewContent(),
    );
  }
}

class SavingsViewContent extends StatelessWidget {
  const SavingsViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SavingsViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);

    return StreamBuilder<SavingsState>(
      stream: vm.stateStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: lang.translate('failed_to_load_goals'),
                message: snapshot.error.toString(),
                actionText: lang.translate('retry'),
                onAction: vm.refresh, // Re-triggers the stream
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: LoadingState()));
        }

        final state = snapshot.data!;

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          appBar: _SavingsAppBar(hasGoals: state.goals.isNotEmpty),
          body: state.goals.isEmpty
              ? Center(
                  child: AnimatedEmptyState(
                    message: lang.translate('No data recorded').toUpperCase(),
                    imagePath: 'assets/images/savings_light.svg',
                    darkImagePath: 'assets/images/savings_dark.svg',
                    animationType: EmptyStateAnimation.bounce,
                  )
                )
              : _SavingsList(state: state, vm: vm),
          floatingActionButton: state.goals.isNotEmpty ? const _AddGoalFAB() : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        );
      },
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
        if (!hasGoals)
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
  final SavingsState state; // Receive the calculated state
  final SavingsViewModel vm;
  
  const _SavingsList({
    required this.state,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          // Pass the state to the stat card for pre-calculated numbers
          SavingsStatCard(state: state), 
          
          const SizedBox(height: 24),
          Text(
            lang.translate('your_goals'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Render the list from state
          ...state.goals.map((goal) => _GoalListItem(goal: goal)),
          
          // Added spacing for FAB
          const SizedBox(height: 80), 
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

