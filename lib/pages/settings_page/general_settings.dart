import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/models/setting_item.dart';
import 'package:provider/provider.dart';
import '../../core/services/preferences.dart';
import '../../core/widgets/settings_page/general_settings/currency_picker.dart';
import '../../models/currency.dart';


class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  final PreferencesService _prefs = PreferencesService();
  
  late String _currency;
  late String _language;
  late String _dateFormat;
  late String _numberFormat;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final currency = await _prefs.getCurrency();
      final language = await _prefs.getLanguage();
      final dateFormat = await _prefs.getDateFormat();
      final numberFormat = await _prefs.getNumberFormat();
      
      setState(() {
        _currency = currency;
        _language = language;
        _dateFormat = dateFormat;
        _numberFormat = numberFormat;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      setState(() {
        _currency = 'USD';
        _language = 'English';
        _dateFormat = 'MM/DD/YYYY';
        _numberFormat = '1,234.56';
        _isLoading = false;
      });
    }
  }

  List<SettingItem>  _getsettings(LanguageProvider lang) => [
    SettingItem(
      id: 'currency',
      title: lang.translate('currency'),
      subtitle: _currency,
      icon: Icons.attach_money,
      type: SettingType.selection,
      value: _currency,
    ),
    SettingItem(
      id: 'language',
      title: lang.translate('language'),
      subtitle: _language,
      icon: Icons.language,
      type: SettingType.selection,
      value: _language,
    ),
    SettingItem(
      id: 'date_format',
      title: lang.translate('date_format'),
      subtitle: _dateFormat,
      icon: Icons.calendar_today,
      type: SettingType.selection,
      value: _dateFormat,
    ),
    SettingItem(
      id: 'number_format',
      title: lang.translate('number_format'),
      subtitle: _numberFormat,
      icon: Icons.numbers,
      type: SettingType.selection,
      value: _numberFormat,
    ),
  ];

  void _handleItemTap(String id) {
    switch (id) {
      case 'currency':
        _showCurrencyPicker();
        break;
      case 'language':
        _showLanguagePicker();
        break;
      case 'date_format':
        _showDateFormatPicker();
        break;
      case 'number_format':
        _showNumberFormatPicker();
        break;
    }
  }

  void _handleItemChanged(String id, dynamic value) async {
    if (id == 'currency') {
      // Talk to the global provider instead of just local state
      await context.read<CurrencyProvider>().updateCurrency(value);
      
      setState(() {
        _currency = value; 
      });

    } else {
      setState(() {
        switch (id) {
          case 'language':
            _language = value;
            break;
          case 'date_format':
            _dateFormat = value;
            break;
          case 'number_format':
            _numberFormat = value;
            break;
        }
      });
    }

    // Save to preferences
    try {
      switch (id) {       
        case 'language':
          await _prefs.setLanguage(value);
          break;
        case 'date_format':
          await _prefs.setDateFormat(value);
          break;
        case 'number_format':
          await _prefs.setNumberFormat(value);
          break;
      }
      debugPrint('$id saved: $value');
    } catch (e) {
      debugPrint('Error saving $id: $e');
    }
  }

  Future<void> _showCurrencyPicker() async {
    final currentCurrency = Currency.getCurrency(_currency);
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.read<LanguageProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final selectedCurrency = await showCurrencyPicker(
      context: context,
      initialCurrency: currentCurrency,
      showFlags: true,
    );
    
    if (selectedCurrency != null) {
      _handleItemChanged('currency', selectedCurrency.code);
      if (!mounted) return;

      setState(() {
        _currency = selectedCurrency.code;
      });
      
      // Show confirmation with example
      final newCf = context.read<CurrencyProvider>().formatter;
      final exampleAmount = newCf.format(1234.56, lang.localeCode);
      
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

  Future<void> _showLanguagePicker() async {
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
                trailing: _language == languages[index] 
                  ? Icon(Icons.check, color: theme.colorScheme.primary) 
                  : null,
                onTap: () => Navigator.pop(context, languages[index]),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null && selected != _language && mounted) {
      // 1. Update the Provider
      await context.read<LanguageProvider>().updateLanguage(selected);

      // 3. Update local UI
      setState(() {
        _language = selected;
      });

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final lang = context.watch<LanguageProvider>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow, 
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(theme),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                lang.translate('regional_format'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Main Settings Group
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: _getsettings(lang).asMap().entries.map((entry) {
                  final isLast = entry.key == _getsettings(lang).length - 1;
                  return _buildCustomSettingsTile(entry.value, isLast);
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),
            _buildDangerZone(theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    final cf = context.watch<CurrencyProvider>().formatter;
    final lang = context.watch<LanguageProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            cf.format(1234.56, lang.localeCode),
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

  Widget _buildCustomSettingsTile(SettingItem item, bool isLast) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: () => _handleItemTap(item.id),
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
          if (!isLast)
            Divider(indent: 60, endIndent: 16, height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildDangerZone(ThemeData theme) {
    final lang = context.watch<LanguageProvider>();
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
            onPressed: _resetToDefaults,
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

  Future<void> _resetToDefaults() async {
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
      await _prefs.clearAll();
      await _loadPreferences();
      
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

  void _showDateFormatPicker() => debugPrint('Show date format picker');
  void _showNumberFormatPicker() => debugPrint('Show number format picker');
}