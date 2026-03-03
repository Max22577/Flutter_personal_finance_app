import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title:  Text(lang.translate('appearance'),
          style: text.titleLarge?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
          )
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, lang.translate('theme_mode')),
                const SizedBox(height: 12),
                _buildModeCard(
                  context: context,
                  icon: Icons.brightness_auto,
                  title: lang.translate('system_default'),
                  subtitle: lang.translate('system_default_sub'),
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                ),
                _buildModeCard(
                  context: context,
                  icon: Icons.light_mode,
                  title: lang.translate('light_mode'),
                  subtitle: lang.translate('light_mode_sub'),
                  isSelected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
                _buildModeCard(
                  context: context,
                  icon: Icons.dark_mode,
                  title: lang.translate('dark_mode'),
                  subtitle: lang.translate('dark_mode_sub'),
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader(context, lang.translate('accent_colors')),
                const SizedBox(height: 16),
                
                // Color Selection Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  children: [
                    _buildColorCircle(context, lang.translate('color_light'), AppColors.lightPrimary, themeProvider),
                    _buildColorCircle(context, lang.translate('color_dark'), AppColors.darkPrimary, themeProvider),
                    _buildColorCircle(context, lang.translate('color_blue'), Colors.blue, themeProvider),
                    _buildColorCircle(context, lang.translate('color_green'), Colors.green, themeProvider),
                    _buildColorCircle(context, lang.translate('color_orange'), Colors.orange, themeProvider),
                  ],
                ),

                const SizedBox(height: 32),
                _buildSectionHeader(context, lang.translate('preview')),
                const SizedBox(height: 12),
                _buildPreviewCard(context),

                const SizedBox(height: 40),
                Center(
                  child: TextButton.icon(
                    onPressed: () => themeProvider.resetToDefaults(),
                    icon: const Icon(Icons.refresh),
                    label: Text(lang.translate('reset_defaults')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: isSelected ? 4 : 0,
        color: isSelected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: isSelected ? colors.primary : null),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: isSelected ? Icon(Icons.check_circle, color: colors.primary) : null,
        ),
      ),
    );
  }

  Widget _buildColorCircle(BuildContext context, String name, Color color, ThemeProvider provider) {
    final isSelected = provider.currentThemeName == name;
    return Column(
      children: [
        GestureDetector(
          onTap: () => provider.changeTheme(name),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (isSelected)
                const Icon(Icons.check, color: Colors.white, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Icon(Icons.shopping_cart, color: theme.colorScheme.onPrimary),
              ),
              title: Text(lang.translate('groceries'), style: theme.textTheme.titleMedium),
              subtitle: Text("${lang.translate('today')} - 3:45 PM", style: theme.textTheme.bodyMedium),
              trailing: CurrencyDisplay(amount: 45.69, isExpense: true,)
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              child: Text(lang.translate('add_transaction')),
            ),
          ],
        ),
      ),
    );
  }
}