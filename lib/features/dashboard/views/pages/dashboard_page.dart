import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/rate_sync_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/shared_widgets/empty_state.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:personal_fin/features/dashboard/views/widgets/dashboard/category_pie_chart.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/features/dashboard/views/widgets/monthly_review_summary.dart';
import 'package:personal_fin/features/dashboard/views/widgets/dashboard/quick_stats.dart';
import 'package:personal_fin/features/dashboard/views/widgets/dashboard/recent_transactions.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();   
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RateSyncProvider>().syncRates();
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardViewModel>(
      create: (context) => DashboardViewModel(
        context.read<MonthlyDataRepository>(),
        context.read<CurrencyProvider>(),
      ),
      child: _DashboardScaffold(),
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    // Safely look up system status bar heights manually
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      extendBodyBehindAppBar: true,
      body: SizedBox.expand( 
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double gradientBackdropHeight = statusBarHeight + kToolbarHeight + textScaler.scale(160);

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: gradientBackdropHeight + textScaler.scale(20), // Added buffer
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, Color.lerp(colors.primary, colors.secondary, 0.5)!],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                
                Positioned.fill(
                  child: SingleChildScrollView(
                    key: const Key('dashboard_main_scroll'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Adjust top padding manually to prevent layout overlaps under the appbar
                    padding: EdgeInsets.fromLTRB(
                      textScaler.scale(16), 
                      statusBarHeight + kToolbarHeight + textScaler.scale(8), 
                      textScaler.scale(16), 
                      textScaler.scale(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: textScaler.scale(120), 
                          ),
                          child: const _DashboardMonthlyReviewSection(),
                        ),
                        SizedBox(height: textScaler.scale(24)),
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
              ],
            );
          },
        )
      ),    
    );
  }
}

// REVIEW SECTION & CARDS

class _DashboardMonthlyReviewSection extends StatelessWidget {
  const _DashboardMonthlyReviewSection();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final vm = context.read<DashboardViewModel>();
    final textScaler = MediaQuery.textScalerOf(context);

    return StreamBuilder<List<MonthlyData>>(
      stream: vm.dashboardReviewStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: textScaler.scale(150),
            child: const Center(child: LoadingState()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: textScaler.scale(160),
            child: Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: lang.translate('error_loading_monthly_data'),
                message: snapshot.error.toString(),
                actionText: lang.translate('retry'),
                onAction: () {},
              ),
            ),
          );
        }

        final data = snapshot.data;


        if (data == null || data.isEmpty) {
          return SizedBox(
            height: textScaler.scale(160),
            child: Center(
              child: EmptyState(
                icon: Icons.info_outline,
                title: lang.translate('no_monthly_data'),
                message: 'Please ensure you have transactions for the current month.',
                actionText: lang.translate('retry'),
                onAction: () {},
              ),
            ),
          );
        }

        return MonthlyReviewSummary(
          monthlyData: data[0],
          previousMonthData: data[1],
          onTap: () => Navigator.pushNamed(context, '/monthly_review'),
          isDashboard: true,
        );
      },
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