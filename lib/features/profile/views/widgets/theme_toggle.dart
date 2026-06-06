import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeToggleTile extends StatelessWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return SwitchListTile(
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
        themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        themeProvider.changeTheme(value ? 'Dark' : 'Light');
      },
    );
  }
}