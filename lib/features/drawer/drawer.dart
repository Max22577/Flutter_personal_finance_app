import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final void Function(String routeName) onNavigate;
  final VoidCallback onLogout;

  const AppDrawer({
    required this.onNavigate,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>();
    final nav = context.watch<NavigationProvider>();
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '/home';

    return Drawer(
      backgroundColor: colors.surface,
      child: Column(
        children: [
          _DrawerHeader(userName: userName, userEmail: userEmail),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Margin spacing for active borders
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: lang.translate('dashboard'),
                  isSelected: (currentRoute == '/home' || currentRoute == '/') && nav.selectedIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    nav.setPage(0);
                  },
                ),
                _AccountGroup(
                  onNavigate: onNavigate,
                  onLogout: onLogout,
                  currentRoute: currentRoute,
                ),
                _MonthlyReport(onNavigate: onNavigate, currentRoute: currentRoute),
                _TransactionGroup(onNavigate: onNavigate, currentRoute: currentRoute),
                _BudgetingGroup(onNavigate: onNavigate, currentRoute: currentRoute),
                _SavingsGroup(onNavigate: onNavigate, currentRoute: currentRoute),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  title: lang.translate('settings'),
                  isSelected: currentRoute == '/settings',
                  onTap: () => onNavigate('/settings'),
                ),
              ],
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          const _ThemeToggleTile(),
          const _DrawerFooter(),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String userName;
  final String userEmail;

  const _DrawerHeader({required this.userName, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return UserAccountsDrawerHeader(
      accountName: Text(userName, 
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onPrimary)),
      accountEmail: Text(userEmail, 
        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimary.withValues(alpha: 0.8))),
      currentAccountPicture: Container(
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.account_balance_wallet_rounded, color: colors.onPrimaryContainer, size: 36),
      ),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHigh : colors.primary,
        image: const DecorationImage(
          image: AssetImage('assets/images/user_header.jpg'),
          fit: BoxFit.cover,
          opacity: 0.25, // Softened context background image opacity
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final activeColor = colors.primary;
    final inactiveColor = colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          // Border lights up entirely matching active state selection
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          dense: true,
          // Icon wrapped in rounded square card background
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.15) : colors.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 20),
          ),
          title: Text(
            title,
            style: isSelected 
                ? theme.textTheme.titleMedium?.copyWith(color: activeColor, fontWeight: FontWeight.bold)
                : theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DrawerGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool hasActiveChild;

  const _DrawerGroup({
    required this.icon,
    required this.title,
    required this.children,
    required this.hasActiveChild,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent), 
        child: ExpansionTile(
          initiallyExpanded: hasActiveChild,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasActiveChild ? colors.primary.withValues(alpha: 0.1) : colors.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: hasActiveChild ? colors.primary : colors.onSurfaceVariant, size: 20),
          ),
          title: Text(
            title, 
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasActiveChild ? colors.primary : colors.onSurface,
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 16.0),
          children: children,
        ),
      ),
    );
  }
}

class _MonthlyReport extends StatelessWidget {
  final Function(String) onNavigate;
  final String currentRoute;
  const _MonthlyReport({required this.onNavigate, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return _DrawerGroup(
      icon: Icons.calculate_rounded,
      title: 'Monthly Report',
      hasActiveChild: currentRoute == '/monthly_review',
      children: [
        _DrawerItem(
          icon: Icons.trending_up_rounded, 
          title: 'Monthly Review', 
          isSelected: currentRoute == '/monthly_review',
          onTap: () => onNavigate('/monthly_review'),
        ),
      ],
    );
  }
}

class _AccountGroup extends StatelessWidget {
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final String currentRoute;

  const _AccountGroup({required this.onNavigate, required this.onLogout, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final nav = context.watch<NavigationProvider>();
    final routes = ['/profile'];
    return _DrawerGroup(
      icon: Icons.person_rounded, 
      title: lang.translate('profile'), 
      hasActiveChild: routes.contains(currentRoute),
      children: [
        _DrawerItem(
          icon: Icons.account_circle_rounded, 
          title: lang.translate('user_profile'), 
          isSelected: (currentRoute == '/home' || currentRoute == '/') && nav.selectedIndex == 3,
          onTap: () {
            Navigator.pop(context);
            nav.setPage(3);
          },
        ),
        _DrawerItem(
          icon: Icons.logout_rounded, 
          title: lang.translate('logout'), 
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  final Function(String) onNavigate;
  final String currentRoute;

  const _TransactionGroup({required this.onNavigate, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final nav = context.watch<NavigationProvider>();
    final routes = ['/categories', '/transactions'];
    return _DrawerGroup(
      icon: Icons.receipt_long_rounded, 
      title: lang.translate('transactions'),
      hasActiveChild: routes.contains(currentRoute),
      children: [
        _DrawerItem(
          icon: Icons.label_rounded,
          title: lang.translate('manage_categories'),
          isSelected: currentRoute == '/categories',
          onTap: () => onNavigate('/categories'),
        ),
        _DrawerItem(
          icon: Icons.paid_rounded, 
          title: lang.translate('view_transactions'),
          isSelected: (currentRoute == '/home' || currentRoute == '/') && nav.selectedIndex == 1,
          onTap: () {
            Navigator.pop(context);
            nav.setPage(1);
          },
        ),
      ],
    );
  }
}

class _BudgetingGroup extends StatelessWidget {
  final Function(String) onNavigate;
  final String currentRoute;

  const _BudgetingGroup({required this.onNavigate, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final nav = context.watch<NavigationProvider>();
    return _DrawerGroup(
      icon: Icons.pie_chart_rounded, 
      title: lang.translate('budgeting'),
      hasActiveChild: currentRoute == '/budgeting',
      children: [
        _DrawerItem(
          icon: Icons.analytics_rounded, 
          title: lang.translate('set_budgets'),
          isSelected: (currentRoute == '/home' || currentRoute == '/') && nav.selectedIndex == 2,
          onTap: () {
            Navigator.pop(context);
            nav.setPage(2);
          },
        ),                   
      ],
    );
  }
}

class _SavingsGroup extends StatelessWidget {
  final Function(String) onNavigate;
  final String currentRoute;

  const _SavingsGroup({required this.onNavigate, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final routes = ['/savings', '/savings/goal'];
    return _DrawerGroup(
      icon: Icons.savings_rounded,
      title: lang.translate('Savings'),
      hasActiveChild: routes.contains(currentRoute),
      children: [
        _DrawerItem(
          icon: Icons.donut_large_rounded, 
          title: lang.translate('savings_progress'),
          isSelected: currentRoute == '/savings',
          onTap: () => onNavigate('/savings'),
        ),
        _DrawerItem(
          icon: Icons.add_task_rounded, 
          title: lang.translate('set_savings_goal'),
          isSelected: currentRoute == '/savings/goal',
          onTap: () => onNavigate('/savings/goal'),
        ),                    
      ],
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: SwitchListTile(
        secondary: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => RotationTransition(
            turns: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: isDark 
            ? Icon(Icons.dark_mode_rounded, key: const ValueKey('dark'), color: colors.primary)
            : Icon(Icons.light_mode_rounded, key: const ValueKey('light'), color: Colors.amber.shade700),
        ),
        title: Text(
          isDark ? 'Dark Mode' : 'Light Mode',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        value: isDark,
        activeThumbColor: colors.primary,
        onChanged: (bool value) {
          if (value) {
            themeProvider.setThemeMode(ThemeMode.dark);
            themeProvider.changeTheme('Dark');
          } else {
            themeProvider.setThemeMode(ThemeMode.light);
            themeProvider.changeTheme('Light');
          }
        },
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Text(
        "App Version 1.0.2",
        style: Theme.of(context).textTheme.labelSmall
      ),
    );
  }
}