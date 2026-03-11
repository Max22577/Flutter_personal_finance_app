import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/features/settings/widgets/currency_picker.dart';
import 'package:personal_fin/features/settings/view_models/general_settings_view_model.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:personal_fin/models/setting_item.dart';
import 'package:provider/provider.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  Future<void> _showCurrencyPicker(BuildContext context, GeneralSettingsViewModel vm) async {
    final currentCurrency = Currency.getCurrency(vm.currency);
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.read<LanguageProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final selectedCurrency = await showCurrencyPicker(
      context: context,
      initialCurrency: currentCurrency,
      showFlags: true,
    );
    
    if (selectedCurrency != null && context.mounted) {
      await vm.updateCurrency(context, selectedCurrency.code);
      
      if (!context.mounted) return;
      
      // Show confirmation with example
      final newCf = context.read<CurrencyProvider>().formatter;
      final exampleAmount = newCf.formatNumber(1234.56, lang.localeCode);
      
      messenger.showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Currency changed to ${selectedCurrency.code}',
                style: TextStyle(color: colors.onPrimaryContainer)
              ),
              const SizedBox(height: 4),
              Text(
                'Example: $exampleAmount',
                style: TextStyle(fontSize: 12,color: colors.onPrimaryContainer),
              ),
            ],
          ),
          backgroundColor: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showLanguagePicker(BuildContext context, GeneralSettingsViewModel vm) async {
    final languages = ['English', 'Swahili', 'French', 'Spanish'];
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.read<LanguageProvider>();

    final String? selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('select_language')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(languages[index]),
                trailing: vm.language == languages[index] 
                  ? Icon(Icons.check, color: theme.colorScheme.primary) 
                  : null,
                onTap: () => Navigator.pop(context, languages[index]),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null && selected != vm.language && context.mounted) {
      // 1. Update the Provider
      await vm.updateLanguage(context, selected);

      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('${lang.translate('lang_changed')} $selected',
            style: TextStyle(color: colors.onPrimaryContainer)
          ),
          backgroundColor: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GeneralSettingsViewModel()..loadSettings(),
      child: Consumer<GeneralSettingsViewModel>(
        builder: (context, vm, _) {
          final lang = context.watch<LanguageProvider>();
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final text = theme.textTheme;

          if (vm.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return Scaffold(
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            appBar: AppBar(
              title: Text(lang.translate('general_settings'), 
                style: text.titleLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.bold,
                )
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeroHeader(context, theme, lang),
                  _buildSettingsList(context, vm, lang),
                  const SizedBox(height: 32),
                  _buildDangerZone(theme, lang, context, vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, ThemeData theme, LanguageProvider lang) {
    final cf = context.watch<CurrencyProvider>().formatter;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            cf.formatNumber(1234.56, lang.localeCode),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.translate('format_preview'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, GeneralSettingsViewModel vm, LanguageProvider lang) {
    final items = [
      SettingItem(id: 'currency', title: lang.translate('currency'), subtitle: vm.currency, icon: Icons.attach_money, type: SettingType.selection,),
      SettingItem(id: 'language', title: lang.translate('language'), subtitle: vm.language, icon: Icons.language, type: SettingType.selection,),
      SettingItem(id: 'date_format', title: lang.translate('date_format'), subtitle: vm.dateFormat, icon: Icons.calendar_today, type: SettingType.selection,),
      SettingItem(id: 'number_format', title: lang.translate('number_format'), subtitle: vm.numberFormat, icon: Icons.numbers, type: SettingType.selection,),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .3)),
      ),
      child: Column(
        children: items.map((item) => _customSettingsTile(
          item,
          context,
          vm         
        )).toList(),
      ),
    );
  }

  Widget _customSettingsTile(SettingItem item, BuildContext context, GeneralSettingsViewModel vm) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: () => _onTileTapped(context, vm, item.id),
      borderRadius: BorderRadius.circular(20), 
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: colors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                // Value display - more prominent than subtitle
                Text(
                  item.subtitle ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: colors.outline, size: 20),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildDangerZone(ThemeData theme, LanguageProvider lang, BuildContext context, GeneralSettingsViewModel vm) {
  
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.translate('danger_zone'),
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _resetToDefaults(context, vm),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(lang.translate('reset_all')),
          ),
        ],
      ),
    );
  }

  void _onTileTapped(BuildContext context, GeneralSettingsViewModel vm, String id) {
    if (id == 'currency') _showCurrencyPicker(context, vm);
    if (id == 'language') _showLanguagePicker(context, vm);
    // ... add other pickers here
  }

  Future<void> _resetToDefaults(BuildContext context, GeneralSettingsViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final lang = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('reset_settings_title')),
        content: Text(lang.translate('reset_settings_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('reset')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      vm.resetAll();
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(lang.translate('reset_done'),         
            style: TextStyle(color: theme.colorScheme.onPrimaryContainer)
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: theme.colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),             
        ),
      );
    }
  }
}