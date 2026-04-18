import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/widgets/custom_appbar.dart';
import 'package:personal_fin/core/widgets/empty_state.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:personal_fin/features/savings/pages/set_goal_page.dart';
import 'package:personal_fin/features/savings/widgets/progress_chart.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';
import '../view_models/savings_view_model.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SavingsViewModel(
        context.read<SavingsRepository>()),
      child: const SavingsViewContent(),
    );
  }
}

class SavingsViewContent extends StatelessWidget {
  const SavingsViewContent({super.key});

  void _addGoal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SetGoalPage(),
      ),
    );
  }

  void _editGoal(SavingsGoal goal, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SetGoalPage(existingGoal: goal),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);

    if (vm.isLoading) return const Scaffold(body: Center(child: LoadingState()));
    if (vm.errorMessage != null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: lang.translate('failed_to_load_goals'),
          message: vm.errorMessage ?? lang.translate('unknown_error'),
          actionText: lang.translate('retry'),
          onAction: () => vm.retry(), 
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: CustomAppBar(
        title: 'savings_goals',
        isRootNav: false, // Tells the widget to use the passed title
        actions: [
          if (vm.goals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: const CircleBorder(),
                ),
                onPressed: () => _addGoal(context),
              ),
            ),
        ],
      ),
      body: vm.goals.isEmpty 
          ? _buildEmptyState(context, lang) 
          : _buildMainContent(context, vm, lang),
      floatingActionButton: vm.goals.isNotEmpty
       ? FloatingActionButton.extended(
            onPressed: () => _addGoal(context),
            heroTag: 'addGoal',
            icon: const Icon(Icons.add),
            label: Text(lang.translate('new_goal')),
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageProvider lang) {
    final illustrationTheme = Theme.of(context).extension<IllustrationTheme>();
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 50.0, end: 0.0), 
        duration: const Duration(seconds: 1),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value), 
            child: child,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/savings.png', 
              width: 180,
              height: 180,
              color: illustrationTheme?.tintColor,
              colorBlendMode: illustrationTheme?.blendMode,
              
            ),
          
            const SizedBox(height: 20),
            Text(
              lang.translate('no_goals_yet'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              lang.translate('start_by_creating'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200, 
              child: ElevatedButton.icon(
                onPressed: () => _addGoal(context),
                icon: const Icon(Icons.add),
                label: Text(lang.translate('create_goal')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                
              ),
            ),
          ],  
        )
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, SavingsViewModel vm, LanguageProvider lang) {
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsCard(context, vm, lang),
          const SizedBox(height: 20),
          Text(lang.translate('your_goals'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...vm.goals.map((goal) {
            return _goalTile(goal, context);
          }),
        ],
      ),
    );
  }

  Widget _goalTile(SavingsGoal goal, BuildContext context) {
    return GestureDetector(
      onTap: () => _editGoal(goal, context),
      child: Column(
        children: [
          ProgressChartWidget(goal: goal),
          const SizedBox(height: 16),
        ],
      ),
    );
    
  }

  Widget _buildStatsCard(BuildContext context, SavingsViewModel vm, LanguageProvider lang) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Icon and Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.insights_rounded, color: colors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  lang.translate('savings_overview'),
                  style: textTheme.labelMedium?.copyWith( 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row with Dividers
          IntrinsicHeight( // Ensures vertical dividers match column height
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatItem(lang.translate('goals'), Text(vm.goals.length.toString(), style: _valueStyle(textTheme)), theme),
                    _buildVerticalDivider(colors), 
                    _buildStatItem(lang.translate('progress'), Text('${(vm.overallProgress * 100).toStringAsFixed(0)}%', 
                        style: _valueStyle(textTheme).copyWith(color: colors.primary)), theme),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: colors.outlineVariant.withValues(alpha: 0.1)),
                ),
                Row(
                  children: [
                    _buildStatItem(lang.translate('target'), CurrencyDisplay(amount: vm.totalTarget, compact: true, style: _valueStyle(textTheme)), theme),
                    _buildVerticalDivider(colors),
                    _buildStatItem(lang.translate('saved'), CurrencyDisplay(amount: vm.totalSaved, compact: true, style: _valueStyle(textTheme)), theme),
                  ],
                ),
              ],
            )
          ),
        ],
      ),
    );
  }

  TextStyle _valueStyle(TextTheme textTheme) => textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );

  Widget _buildVerticalDivider(ColorScheme colors) {
    return VerticalDivider(
      color: colors.outlineVariant.withValues(alpha: 0.2),
      thickness: 1,
      indent: 8,
      endIndent: 8,
    );
  }

  Widget _buildStatItem(String label, Widget valueWidget, ThemeData theme) {
    
    return Expanded( 
      child: Column(
        children: [
          valueWidget,
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 9,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

}