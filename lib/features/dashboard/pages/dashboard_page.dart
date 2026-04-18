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
    return const DashboardViewContent();
  }
}

class DashboardViewContent extends StatelessWidget {
  const DashboardViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Monthly Review Section
              _buildMonthlyReview(vm, lang, context),

              const SizedBox(height: 16),

              const CategoryPieChart(),
              
              const SizedBox(height: 32),
              const QuickStats(height: 220),

              const SizedBox(height: 25),
              RecentTransactions(
                maxItems: 5,
                onViewAll: () { /* Navigate via NavProvider */ },
              ),

              const SizedBox(height: 16),
              _buildQuickActions(context, lang),
              
              const SizedBox(height: 120), // Space for FAB/BottomBar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyReview(DashboardViewModel vm, LanguageProvider lang, BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: LoadingState());
    }

    if (vm.errorMessage != null || vm.currentMonthData == null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: lang.translate('error_loading_monthly_data'),
          message: vm.errorMessage!,
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


  Widget _buildQuickActions(BuildContext context, LanguageProvider lang) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.translate('quick_actions'), 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.add_to_photos), 
              title: Text(lang.translate('set_next_budget')),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.star_border), 
              title: Text(lang.translate('review_savings_goals')),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}