import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/widgets/shared/custom_appbar.dart';
import 'package:personal_fin/core/widgets/shared/top_navbar.dart';
import 'package:personal_fin/core/widgets/drawer/drawer.dart';
import 'package:personal_fin/features/budgeting/pages/budgeting_page.dart';
import 'package:personal_fin/features/dashboard/pages/dashboard_page.dart';
import 'package:personal_fin/features/profile/pages/profile_page.dart';
import 'package:personal_fin/features/transactions/pages/transactions.dart';

import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  void _handleUserLogout() async {
    // 1. Close the drawer
    Navigator.of(context).pop();
    final lang = context.read<LanguageProvider>();

    try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('logout_successful'),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 3),
          ),
        ); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lang.translate('logout_failed')}: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleDrawerNavigation(String routeName) {
    Navigator.of(context).pop();

    final Map<String, int> routeToIndex = {
      '/dashboard': 0,
      '/transactions': 1,
      '/budgeting': 2,
      '/profile': 3,
    };

    if (routeToIndex.containsKey(routeName)) {
      final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
      navigationProvider.setPage(routeToIndex[routeName]!);
    } else {
      // Handle auxiliary pages
      // ... your existing auxiliary page logic
      Navigator.of(context).pushNamed(routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();
    
    final int selectedIndex = navigationProvider.selectedIndex;

    final List<Widget> widgetOptions = [
      const DashboardPage(), 
      TransactionsPage(isActive: selectedIndex == 1), 
      const BudgetingPage(), 
      const ProfilePage(), 
    ];

    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'User Profile'; 
    final String email = user?.email ?? 'Not Signed In';

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      extendBody: true,
      appBar: const CustomAppBar(
        isRootNav: true, // Tells the widget to use NavigationProvider for title and actions
      ), 
      
      drawer: AppDrawer(
        onNavigate: _handleDrawerNavigation,
        onLogout: _handleUserLogout, 
        userName: displayName,
        userEmail: email,
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: widgetOptions,
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
            child: Container(
              color: colors.surface.withValues(alpha: 0.4), 
              child: BottomNavigationBar(
                items:  <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded), 
                    label: lang.translate('dashboard'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.swap_horiz_rounded), 
                    label: lang.translate('transactions'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_graph_rounded), 
                    label: lang.translate('budgeting'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_circle), 
                    label: lang.translate('profile'),
                  ),
                ],
                currentIndex: navigationProvider.selectedIndex,
                selectedItemColor: colors.primary, 
                unselectedItemColor: colors.onSurfaceVariant.withValues(alpha: 0.7),
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed, 
                onTap: (index) {
                  navigationProvider.setPage(index);
                },
                elevation: 0, 
              ),
            ),
          ),
        ),
      ),
    );
  }
}