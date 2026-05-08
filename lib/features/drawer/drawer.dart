import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
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

    return Drawer(
      backgroundColor: colors.surface,
      child: Column(
        children: [
          _DrawerHeader(userName: userName, userEmail: userEmail),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: lang.translate('dashboard'),
                  onTap: () => onNavigate('/dashboard'),
                ),
                _AccountGroup(
                  onNavigate: onNavigate,
                  onLogout: onLogout,
                ),
                _FinancialToolsGroup(onNavigate: onNavigate),
                _TransactionGroup(onNavigate: onNavigate),
                _BudgetingGroup(onNavigate: onNavigate),
                _SavingsGroup(onNavigate: onNavigate),
                _DrawerItem(
                  icon: Icons.settings,
                  title: lang.translate('settings'),
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
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.onPrimary)),
      accountEmail: Text(userEmail, 
        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimary.withValues(alpha: 0.8))),
      currentAccountPicture: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(Icons.account_balance_wallet, color: colors.onPrimaryContainer, size: 40),
      ),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHigh : colors.primary,
        image: const DecorationImage(
          image: AssetImage('assets/images/user_header.jpg'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

class _DrawerGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _DrawerGroup({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExpansionTile(
      leading: Icon(icon, color: colors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: children,
    );
  }
}

class _FinancialToolsGroup extends StatelessWidget {
  final Function(String) onNavigate;
  const _FinancialToolsGroup({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    // You can access LangProvider here via context.watch
    return _DrawerGroup(
      icon: Icons.calculate_rounded,
      title: 'Financial Tools',
      children: [
        _DrawerItem(
          icon: Icons.trending_up, 
          title: 'Savings Calculator', 
          onTap: () => onNavigate('/tools/savings')
        ),
      ],
    );
  }
}

class _AccountGroup extends StatelessWidget {
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const _AccountGroup({required this.onNavigate, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _DrawerGroup(
      icon: Icons.person_outline, 
      title: lang.translate('profile'), 
      children: [
        _DrawerItem(
          icon: Icons.account_circle, 
          title: lang.translate('user_profile'), 
          onTap: () => onNavigate('/profile'),
        ),
        _DrawerItem(
          icon: Icons.logout, 
          title: lang.translate('logout'), 
          onTap: onLogout
        ),
      ]
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  final Function(String) onNavigate;

  const _TransactionGroup({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _DrawerGroup(
      icon: Icons.category_rounded,
      title: lang.translate('transactions'),
      children: [
        _DrawerItem(
          icon: Icons.label_important_outline,
          title: lang.translate('manage_categories'),
          onTap: () => onNavigate('/categories'),
        ),
        _DrawerItem(
          icon: Icons.attach_money,
          title: lang.translate('view_transactions'),
          onTap: () => onNavigate('/transactions'),
        ),                    
      ],
    );
  }
}

class _BudgetingGroup extends StatelessWidget {
  final Function(String) onNavigate;

  const _BudgetingGroup({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _DrawerGroup(
      icon: Icons.attach_money,
      title: lang.translate('budgeting'),
      children: [
        _DrawerItem(
          icon: Icons.attach_money,
          title: lang.translate('set_budgets'),
          onTap: () => onNavigate('/budgeting'),
        ),                   
      ],
    );
  }
}

class _SavingsGroup extends StatelessWidget {
  final Function(String) onNavigate;

  const _SavingsGroup({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _DrawerGroup(
      icon: Icons.wallet_travel,
      title: lang.translate('savings'),
      children: [
        _DrawerItem(
          icon: Icons.attach_money,
          title: lang.translate('savings_progress'),
          onTap: () => onNavigate('/savings'),
        ),
        _DrawerItem(
          icon: Icons.wallet_travel,
          title: lang.translate('set_savings_goal'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: SwitchListTile(
        secondary: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => RotationTransition(
            turns: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          // Unique keys are required for AnimatedSwitcher to trigger
          child: isDark 
            ? Icon(Icons.dark_mode, key: const ValueKey('dark'), color: colors.primary)
            : Icon(Icons.light_mode, key: const ValueKey('light'), color: Colors.deepPurpleAccent),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant
        ),
      ),
    );
  }
}