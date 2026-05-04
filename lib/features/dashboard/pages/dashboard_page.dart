import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/widgets/empty_state.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:personal_fin/features/dashboard/widgets/category_pie_chart.dart';
import 'package:personal_fin/features/dashboard/widgets/monthly_review.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/features/dashboard/widgets/quick_stats.dart';
import 'package:personal_fin/features/dashboard/widgets/recent_transactions.dart';
import 'package:provider/provider.dart';
import 'monthly_review_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardScaffold();
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: RefreshIndicator(
        onRefresh: () async => await Future.wait([
          context.read<TransactionRepository>().refresh(),
          context.read<MonthlyDataRepository>().refresh(),
        ]),
        child: SingleChildScrollView(
          key: const Key('dashboard_main_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(textScaler.scale(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DashboardMonthlyReviewSection(),
              SizedBox(height: textScaler.scale(16)),
              const CategoryPieChart(),
              SizedBox(height: textScaler.scale(16)),
              const QuickStats(),
              SizedBox(height: textScaler.scale(24)),
              RecentTransactions(
                maxItems: 5,
                onViewAll: () => Navigator.pushNamed(context, '/transactions'),
              ),
              SizedBox(height: textScaler.scale(16)),
              const _QuickActionsCard(),
              SizedBox(height: textScaler.scale(120)), // Space for FAB/BottomBar
            ],
          ),
        ),
      ),
    );
  }
}

// REVIEW SECTION & CARDS

class _DashboardMonthlyReviewSection extends StatelessWidget {
  const _DashboardMonthlyReviewSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final lang = context.watch<LanguageProvider>();

    if (vm.isLoading) {
      return const Center(child: LoadingState());
    }

    if (vm.errorMessage != null || vm.currentMonthData == null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: lang.translate('error_loading_monthly_data'),
          message: vm.errorMessage ?? 'Unknown error',
          actionText: lang.translate('retry'),
          onAction: () => vm.retry(),
        ),
      );
    }

    return MonthlyReview(
      monthlyData: vm.currentMonthData!,
      previousMonthData: vm.previousMonthData,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MonthlyReviewPage(
            month: DateTime.now(),
            customTitle: lang.translate('this_month'),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();
    final textScaler = MediaQuery.textScalerOf(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(textScaler.scale(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('quick_actions'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: textScaler.scale(12)),
            _ActionTile(
              icon: Icons.add_to_photos,
              label: lang.translate('set_next_budget'),
              onTap: () {},
            ),
            _ActionTile(
              icon: Icons.star_border,
              label: lang.translate('review_savings_goals'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return ListTile(
      leading: Icon(icon, size: textScaler.scale(24)),
      title: Text(label),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.comfortable,
    );
  }
}