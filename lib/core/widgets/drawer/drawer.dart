import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    
    return Drawer(
      backgroundColor: colors.surface,
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              userName, 
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onPrimary,
              ),
            ),
            accountEmail: Text(
              userEmail,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceContainerHigh : colors.primary,
              image: DecorationImage(
                image: const AssetImage('assets/images/user_header.jpg'), 
                fit: BoxFit.cover,
                opacity: isDark ? 0.3 : 0.5,
                alignment: Alignment.center,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.account_balance_wallet, 
                color: colors.onPrimaryContainer, 
                size: 40,
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // --- Dashboard Menu Item ---
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  title: lang.translate('dashboard'),
                  onTap: () => onNavigate('/dashboard'),
                ),
                
                // --- Profile Expansion ---
                _buildExpansionTile(
                  context: context,
                  icon: Icons.person_outline,
                  title: lang.translate('profile'),
                  children: [
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.account_circle,
                      title: lang.translate('user_profile'),
                      color: colors.primary,
                      onTap: () => onNavigate('/profile'),
                    ),
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.logout,
                      title: lang.translate('logout'),
                      color: colors.error,
                      onTap: onLogout,
                    ),
                  ],
                ),
                
                // --- Financial Tools Expansion ---
                _buildExpansionTile(
                  context: context,
                  icon: Icons.calculate_rounded,
                  title: 'Financial Tools',
                  children: [
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.trending_up,
                      title: 'Savings Calculator',
                      color: AppColors.incomeGreen, 
                      onTap: () => onNavigate('/tools/savings'),
                    ),
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.analytics_rounded,
                      title: 'Monthly Report',
                      color: colors.secondary,
                      onTap: () => onNavigate('/tools/report'),
                    ),
                  ],
                ),

                // --- Settings ---
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: lang.translate('settings'),
                  onTap: () => onNavigate('/settings'),
                ),

                Divider(color: colors.outlineVariant.withValues(alpha: 0.3)),

                _buildExpansionTile(
                  context: context,
                  icon: Icons.category_rounded,
                  title: lang.translate('transactions'),
                  children: [
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.label_important_outline,
                      title: lang.translate('manage_categories'),
                      color: colors.primary,
                      onTap: () => onNavigate('/categories'),
                    ),
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.attach_money,
                      title: lang.translate('view_transactions'),
                      color: colors.primary,
                      onTap: () => onNavigate('/transactions'),
                    ),                    
                  ],
                ),
                
                _buildExpansionTile(
                  context: context,
                  icon: Icons.attach_money,
                  title: lang.translate('budget'),

                  children: [
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.attach_money,
                      title: lang.translate('set_budgets'),
                      color: colors.primary,
                      onTap: () => onNavigate('/budgeting'),
                    ),
                  ],
                ),
                
                _buildExpansionTile(
                  context: context,
                  icon: Icons.wallet_travel,
                  title: lang.translate('savings'),
                  children: [
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.attach_money,
                      title: lang.translate('savings_progress'),
                      color: AppColors.lightPrimary, 
                      onTap: () => onNavigate('/savings'),
                    ),
                    _buildSubMenuItem(
                      context: context,
                      icon: Icons.wallet_travel,
                      title: lang.translate('set_savings_goal'),
                      color: AppColors.lightPrimary,
                      onTap: () => onNavigate('/savings/goal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: colors.outlineVariant.withValues(alpha: 0.3), indent: 16, endIndent: 16),

          _buildThemeToggle(context: context),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: Text(
              "App Version 1.0.2",
              style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),          
        ],
      ),
    );
  }

  // Helper method for drawer items
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return ListTile(
      leading: Icon(
        icon,
        color: colors.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600
        ),
      ),
      onTap: onTap,
    );
  }

  // Helper method for expansion tiles
  Widget _buildExpansionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return ExpansionTile(
      leading: Icon(
        icon,
        color: colors.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      collapsedIconColor: colors.onSurfaceVariant,
      iconColor: colors.primary,
      shape: const Border(),
      children: children,
    );
  }

  // Helper method for submenu items
  Widget _buildSubMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 20,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 30),
    );
  }

  // Helper method for theme toggle
  Widget _buildThemeToggle({required BuildContext context}) {
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