import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/features/dashboard/view_models/quick_stats_view_model.dart';
import 'package:personal_fin/features/dashboard/view_models/recent_transactions_view_model.dart';
import 'package:personal_fin/features/home/view_models/home_view_model.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/widgets/custom_appbar.dart';
import 'package:personal_fin/features/drawer/drawer.dart';
import 'package:personal_fin/features/budgeting/pages/budgeting_page.dart';
import 'package:personal_fin/features/dashboard/pages/dashboard_page.dart';
import 'package:personal_fin/features/profile/pages/profile_page.dart';
import 'package:personal_fin/features/transactions/pages/transactions.dart';

class HomePage extends StatelessWidget {
  final DashboardViewModel? dashboardViewModel;
  final QuickStatsViewModel? quickStatsViewModel;
  final RecentTransactionsViewModel? recentTransactionsViewModel;
  final ProfileViewModel? profileViewModel; 

  const HomePage({
    super.key,
    this.dashboardViewModel,
    this.quickStatsViewModel,
    this.recentTransactionsViewModel,
    this.profileViewModel,

  });

  void _onNavigate(BuildContext context, String routeName) {
    Navigator.pop(context); // Close drawer
    
    final vm = context.read<HomeViewModel>();
    final nav = context.read<NavigationProvider>();
    final tabIndex = vm.getTabIndex(routeName);

    if (tabIndex != null) {
      nav.setPage(tabIndex);
    } else {
      Navigator.of(context).pushNamed(routeName);
    }
  }

  void _onLogout(BuildContext context) async {
    final vm = context.read<HomeViewModel>();
    final lang = context.read<LanguageProvider>();
    final colors = Theme.of(context).colorScheme;

    Navigator.pop(context); 

    final success = await vm.signOut();

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        _showSnackBar(context, lang.translate('logout_successful'), colors.primaryContainer, colors.onPrimaryContainer);
      } else {
        _showSnackBar(context, lang.translate('logout_failed'), colors.errorContainer, colors.onErrorContainer);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color bg, Color text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: text)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final nav = context.watch<NavigationProvider>();
    final lang = context.watch<LanguageProvider>();
    final colors = Theme.of(context).colorScheme;

    final List<Widget> pages = [
      const DashboardPage(),
      TransactionsPage(isActive: nav.selectedIndex == 1),
      const BudgetingPage(),
      ProfilePage(viewModel: profileViewModel,),
    ];

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      extendBody: true,
      appBar: const CustomAppBar(isRootNav: true),
      drawer: AppDrawer(
        onNavigate: (route) => _onNavigate(context, route),
        onLogout: () => _onLogout(context),
        userName: vm.displayName,
        userEmail: vm.email,
      ),
      body: IndexedStack(
        index: nav.selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomBar(context, nav, lang, colors),
    );
  }

  Widget _buildBottomBar(BuildContext context, NavigationProvider nav, LanguageProvider lang, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: colors.surface.withValues(alpha: 0.4),
            child: BottomNavigationBar(
              currentIndex: nav.selectedIndex,
              onTap: nav.setPage,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: colors.primary,
              unselectedItemColor: colors.onSurfaceVariant.withValues(alpha: 0.7),
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.dashboard_rounded), label: lang.translate('dashboard')),
                BottomNavigationBarItem(icon: const Icon(Icons.swap_horiz_rounded), label: lang.translate('transactions')),
                BottomNavigationBarItem(icon: const Icon(Icons.auto_graph_rounded), label: lang.translate('budgeting')),
                BottomNavigationBarItem(icon: const Icon(Icons.account_circle), label: lang.translate('profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}