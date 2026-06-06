import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:personal_fin/core/shared_widgets/custom_appbar.dart';
import 'package:personal_fin/features/settings/view_models/general_settings_view_model.dart';
import 'package:personal_fin/core/shared_widgets/currency_picker.dart';
import 'package:personal_fin/features/settings/views/widgets/general_settings/hero_header.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:personal_fin/models/setting_item.dart';
import 'package:provider/provider.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GeneralSettingsViewModel()..loadSettings(),
      child: Consumer<GeneralSettingsViewModel>(
        builder: (context, vm, _) {
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            appBar: const CustomAppBar(
              title: 'general_settings',
              isRootNav: false,
            ),
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const _SettingsBody(),
          );
        },
      ),
    );
  }
}

/// Main Body of the settings
class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          HeroHeader(),
          _SettingsList(),
          SizedBox(height: 32),
          _DangerZone(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// The list of settings tiles
class _SettingsList extends StatelessWidget {
  const _SettingsList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralSettingsViewModel>();
    final lang = context.watch<LanguageProvider>();

    final items = [
      SettingItem(id: 'currency', title: lang.translate('currency'), subtitle: vm.currency, icon: Icons.attach_money, type: SettingType.selection),
      SettingItem(id: 'language', title: lang.translate('language'), subtitle: vm.language, icon: Icons.language, type: SettingType.selection),
      SettingItem(id: 'date_format', title: lang.translate('date_format'), subtitle: vm.dateFormat, icon: Icons.calendar_today, type: SettingType.selection),
      SettingItem(id: 'number_format', title: lang.translate('number_format'), subtitle: vm.numberFormat, icon: Icons.numbers, type: SettingType.selection),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .3)),
      ),
      child: Column(
        children: items.map((item) => _CustomSettingsTile(item: item)).toList(),
      ),
    );
  }
}

/// Individual Tile class
class _CustomSettingsTile extends StatelessWidget {
  final SettingItem item;
  const _CustomSettingsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final vm = context.read<GeneralSettingsViewModel>();

    return InkWell(
      onTap: () => _handleTap(context, vm),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
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
    );
  }

  void _handleTap(BuildContext context, GeneralSettingsViewModel vm) {
    // Logic for pickers stays here or moves to a mixin/controller
    if (item.id == 'currency') _DialogUtils.currencyPicker(context, vm);
    if (item.id == 'language') _DialogUtils.showLanguagePicker(context, vm);
    if (item.id == 'date_format') _DialogUtils.showDateFormatPicker(context, vm);
  }
}

/// Danger Zone section
class _DangerZone extends StatelessWidget {
  const _DangerZone();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();
    final vm = context.read<GeneralSettingsViewModel>();

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
            onPressed: () => _DialogUtils.showResetDialog(context, vm),
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
}

/// Helper class to hold static dialog logic to keep UI classes clean
class _DialogUtils {
  static Future<void> currencyPicker(BuildContext context, GeneralSettingsViewModel vm) async {
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
      final exampleAmount = newCf.formatDisplay(1234.56, lang.localeCode);
      
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

  static Future<void> showLanguagePicker(BuildContext context, GeneralSettingsViewModel vm) async {
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
      await vm.updateLanguage(context, selected);

      if (!context.mounted) return;
      AppFeedback.show(messenger, '${lang.translate('lang_changed')} $selected', colors: colors, textTheme: theme.textTheme, isError: false);     
    }
  }

  static Future<void> showDateFormatPicker(BuildContext context, GeneralSettingsViewModel vm) async {
    // Available format pattern keys
    final formats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'dd MMM yyyy', 'yyyy-MM-dd'];
    
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.read<LanguageProvider>();
    
    final now = DateTime.now();

    final String? selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('select_date_format')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: formats.length,
            itemBuilder: (context, index) {
              final pattern = formats[index];
              // Render a real preview using the pattern selection and current language configuration
              final preview = DateFormat(pattern, lang.localeCode).format(now);

              return ListTile(
                title: Text(pattern),
                subtitle: Text(preview, style: TextStyle(color: colors.onSurfaceVariant)),
                trailing: vm.dateFormat == pattern 
                  ? Icon(Icons.check, color: colors.primary) 
                  : null,
                onTap: () => Navigator.pop(context, pattern),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null && selected != vm.dateFormat && context.mounted) {
      await vm.updateDateFormat(context, selected);

      if (!context.mounted) return;
      AppFeedback.show(
        messenger, 
        '${lang.translate('date_format_changed')}: ${DateFormat(selected, lang.localeCode).format(now)}', 
        colors: colors, 
        textTheme: theme.textTheme, 
        isError: false
      );     
    }
  }

  static Future<void> showResetDialog(BuildContext context, GeneralSettingsViewModel vm) async {
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
      AppFeedback.show(messenger,lang.translate('reset_done'), colors: theme.colorScheme, textTheme: theme.textTheme, isError: false);         

    }
  }
}