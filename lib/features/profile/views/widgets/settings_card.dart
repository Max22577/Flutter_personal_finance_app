import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/shared_widgets/currency_picker.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';
import 'package:personal_fin/features/profile/views/widgets/theme_toggle.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:provider/provider.dart';
import 'glowing_expansion_tile.dart';

class SettingsCard extends StatefulWidget {
  const SettingsCard({super.key});

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  int? _expandedIndex;

  // Language Picker Dialog Trigger
  Future<void> _changeLanguage(BuildContext context) async {
    final languages = ['English', 'Swahili', 'French', 'Spanish'];
    final theme = Theme.of(context);
    final langProvider = context.read<LanguageProvider>();
    final currentLang = langProvider.currentLanguage; 

    final String? selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langProvider.translate('select_language')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(languages[index]),
                trailing: currentLang == languages[index]
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, languages[index]),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null && selected != currentLang && context.mounted) {
      await langProvider.updateLanguage(selected);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${langProvider.translate('lang_changed')} $selected')),
      );
    }
  }

  // Currency Picker Trigger using your existing showCurrencyPicker configuration
  Future<void> _changeCurrency(BuildContext context) async {
    final currencyProvider = context.read<CurrencyProvider>();
    final currentCurrencyCode = currencyProvider.currentCurrency; 
    final currentCurrency = Currency.getCurrency(currentCurrencyCode);
    final lang = context.read<LanguageProvider>();

    final selectedCurrency = await showCurrencyPicker(
      context: context,
      initialCurrency: currentCurrency,
      showFlags: true,
    );

    if (selectedCurrency != null && context.mounted) {
      await currencyProvider.updateCurrency(selectedCurrency.code);
      if (!context.mounted) return;

      final newCf = context.read<CurrencyProvider>().formatter;
      final exampleAmount = newCf.formatDisplay(1234.56, lang.localeCode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Currency changed to ${selectedCurrency.code}'),
              const SizedBox(height: 4),
              Text('Example: $exampleAmount', style: const TextStyle(fontSize: 12)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lang = context.watch<LanguageProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final vm = context.read<ProfileViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Language Tile
          GlowingExpansionTile(
            index: 0,
            currentIndex: _expandedIndex,
            icon: Icons.translate_rounded,
            title: lang.translate('language'),
            onExpansionChanged: (expanded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _expandedIndex = expanded ? 0 : null;
                  });
                }
              });
            },
            children: [
              ListTile(
                title: Text(
                  lang.currentLanguage,
                  style: textTheme.labelLarge?.copyWith(
                    letterSpacing: 0.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.outline),
                onTap: () => _changeLanguage(context),
              ),
            ],
          ),
          // Currency Tile
          GlowingExpansionTile(
            index: 1,
            currentIndex: _expandedIndex,
            icon: Icons.payments_rounded,
            title: lang.translate('currency'),
            onExpansionChanged: (expanded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _expandedIndex = expanded ? 1 : null;
                  });
                }
              });
            },
            children: [
              ListTile(
                title: Text(
                  currencyProvider.currentCurrency,
                  style: textTheme.bodyLarge?.copyWith(
                    letterSpacing: 0.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.outline),
                onTap: () => _changeCurrency(context),
              ),
            ],
          ),
          // Theme Tile
          GlowingExpansionTile(
            index: 2,
            currentIndex: _expandedIndex,
            icon: Icons.dark_mode_rounded,
            title: 'Theme Preferences',
            onExpansionChanged: (expanded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _expandedIndex = expanded ? 2 : null;
                  });
                }
              });
            },
            children: const [
              ThemeToggleTile(),
            ],
          ),
          // Notifications Tile
          GlowingExpansionTile(
            index: 3,
            currentIndex: _expandedIndex,
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            onExpansionChanged: (expanded) => setState(() => _expandedIndex = expanded ? 3 : null),
            children: [
              SwitchListTile(title: const Text('Push Notifications'), value: true, onChanged: (v) {}),
            ],
          ),
          // Logout Tile
          GlowingExpansionTile(
            index: 4,
            currentIndex: _expandedIndex,
            icon: Icons.logout_rounded,
            title: 'Session Management',
            isLogout: true,
            onExpansionChanged: (expanded) => setState(() => _expandedIndex = expanded ? 4 : null),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => vm.signOut(),
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Logout Account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(color: colors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}