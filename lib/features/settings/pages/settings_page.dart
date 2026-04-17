import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/custom_appbar.dart';
import 'package:personal_fin/features/settings/widgets/profile_card.dart';
import 'package:personal_fin/features/settings/widgets/settings_section.dart';
import 'package:personal_fin/features/settings/pages/general_settings_page.dart';
import 'package:personal_fin/features/settings/view_models/settings_view_model.dart';
import 'package:personal_fin/models/setting_item.dart';
import 'package:personal_fin/features/settings/pages/appearance.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Define all settings items for main hub
  List<SettingItem>  _getgeneralSettings(LanguageProvider lang) => [
    SettingItem(
      id: 'appearance',
      title: lang.translate('appearance_title'),
      subtitle: lang.translate('appearance_sub'),
      icon: Icons.color_lens,
      type: SettingType.navigation,
    ),
    SettingItem(
      id: 'general',
      title: lang.translate('general_settings_title'),
      subtitle: lang.translate('general_settings_sub'),
      icon: Icons.settings,
      type: SettingType.navigation,
    ),
  ];

  List<SettingItem>  _getnotificationSettings(LanguageProvider lang) => [
    SettingItem(
      id: 'notifications',
      title: lang.translate('notifications_title'),
      subtitle: lang.translate('notifications_sub'),
      icon: Icons.notifications,
      type: SettingType.navigation,
    ),
    SettingItem(
      id: 'push_enabled',
      title: lang.translate('push_notifications'),
      subtitle: lang.translate('push_notifications_sub'),
      icon: Icons.notifications_active,
      type: SettingType.toggle, // Changed to toggle
      value: true, 
    ),
  ];

  List<SettingItem> _getsecuritySettings(LanguageProvider lang) => [
    SettingItem(
      id: 'security',
      title: lang.translate('security_title'),
      subtitle: lang.translate('security_sub'),
      icon: Icons.security,
      type: SettingType.navigation,
    ),
  ];

  List<SettingItem>  _getbudgetSettings(LanguageProvider lang) => [
    SettingItem(
      id: 'budget',
      title: lang.translate('budget_goals_title'),
      subtitle: lang.translate('budget_goals_sub'),
      icon: Icons.account_balance_wallet,
      type: SettingType.navigation,
    ),
  ];

  List<SettingItem>  _getdataSettings(LanguageProvider lang) => [
    SettingItem(
      id: 'data',
      title: lang.translate('data_mgmt_title'),
      subtitle: lang.translate('data_mgmt_sub'),
      icon: Icons.storage,
      type: SettingType.navigation,
    ),
    SettingItem(
      id: 'export_csv',
      title: lang.translate('export_data'),
      subtitle: lang.translate('export_data_sub'),
      icon: Icons.file_download,
      type: SettingType.action, 
    ),
    SettingItem(
      id: 'delete_account',
      title: lang.translate('delete_account'),
      subtitle: lang.translate('delete_account_sub'),
      icon: Icons.delete_forever,
      type: SettingType.destructive, // Changed to destructive
    ),
  ];

  List<SettingItem> _getaboutSettings(LanguageProvider lang) => [
    SettingItem(
      id: 'about',
      title: lang.translate('about_legal'),
      subtitle: lang.translate('about_legal_sub'),
      icon: Icons.info,
      type: SettingType.navigation,
    ),
  ];

  // Navigation handlers
  void _navigateToPage(String pageId, BuildContext context) {
    final lang = context.read<LanguageProvider>();  
    switch (pageId) {
      case 'appearance':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AppearancePage()));
        break;
      case 'general':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const GeneralSettingsPage()));
        break;
      default:
      // For all other pages, show a snackbar message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('page_coming_soon')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _searchSettings() {
    debugPrint('Search settings');
  }
  void _signOut(BuildContext context, SettingsViewModel vm) async {
    final lang = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('sign_out')),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang.translate('sign_out')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.signOut();
      
      // 3. Navigate away (Context-dependent logic stays in View)
      if (context.mounted) {
        // This removes all routes and pushes the login page
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final lang = context.watch<LanguageProvider>();

          return Scaffold(
            backgroundColor: colors.surfaceContainerLow,
            appBar: CustomAppBar(
              title: 'settings',
              isRootNav: false, // Tells the widget to use the passed title
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.search),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      shape: const CircleBorder(),
                    ),
                    onPressed: _searchSettings,
                    tooltip: lang.translate('search_settings'),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Card
                  SimpleProfileCard(
                    user: vm.user,
                    onTap: () => _showEditProfileSheet(context, vm),
                  ),

                  // Settings Sections (Using your existing SettingSection widget)
                  SettingsSection(
                    title: lang.translate('personalization'),
                    items: _getgeneralSettings(lang),
                    onSettingTapped: (SettingItem item) {
                      switch (item.id) {
                        case 'appearance':
                          _navigateToPage('appearance', context);
                          break;
                        case 'general':
                          _navigateToPage('general', context);
                          break;
                        default:
                          debugPrint('Unknown setting tapped: ${item.id}');
                      }
                    },
                  ),

                  SettingsSection(
                    title: lang.translate('alerts_notifications'),
                    items: _getnotificationSettings(lang),
                    onSettingTapped: (SettingItem item) {
                      if (item.id == 'notifications') {
                        _navigateToPage('notifications', context);
                      }
                    },
                  ),

                  SettingsSection(
                    title: lang.translate('security_title'),
                    subtitle: vm.user == null ? lang.translate('security_sign_in') : null,
                    items: _getsecuritySettings(lang),
                    onSettingTapped: (SettingItem item) {
                      if (item.id == 'security') {
                        _navigateToPage('security', context);
                      }
                    },
                  ),

                  SettingsSection(
                    title: lang.translate('financial_planning'),
                    items: _getbudgetSettings(lang),
                    onSettingTapped: (SettingItem item) {
                      if (item.id == 'budget') {
                        _navigateToPage('budget', context);
                      }
                    },
                  ),

                  SettingsSection(
                    title: lang.translate('data_mgmt_title'),
                    subtitle: lang.translate('data_mgmt_sub'),
                    items: _getdataSettings(lang),
                    onSettingTapped: (SettingItem item) {
                      if (item.id == 'data') {
                        _navigateToPage('data', context);
                      }
                    },
                  ),

                  SettingsSection(
                    title: lang.translate('about'),
                    items: _getaboutSettings(lang),
                    onSettingTapped: (SettingItem item) {
                      if (item.id == 'about') {
                        _navigateToPage('about', context);
                      }
                    },
                  ),

                  if (vm.user != null) _buildSignOutButton(context, vm, lang),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('FinManager v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, SettingsViewModel vm, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(lang.translate('sign_out')),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => _signOut(context, vm),
        ),
      ),
    );
  }

  // Logic for the Profile Modal
  void _showEditProfileSheet(BuildContext context, SettingsViewModel vm) {
    final nameController = TextEditingController(text: vm.user?.displayName);
    final lang = context.read<LanguageProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(
        value: vm, // Pass the existing VM to the sheet
        child: Consumer<SettingsViewModel>(
          builder: (context, vm, _) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _buildFrostedContainer(
              context,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHandleBar(),
                  GestureDetector(
                    onTap: () => vm.pickImage(),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: vm.selectedImage != null 
                              ? FileImage(vm.selectedImage!) 
                              : (vm.user?.photoURL != null ? NetworkImage(vm.user!.photoURL!) : null) as ImageProvider?,
                          child: vm.selectedImage == null && vm.user?.photoURL == null 
                              ? const Icon(Icons.person, size: 50) : null,
                        ),
                        Positioned( 
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            radius: 18,
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(lang.translate('edit_profile'), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: lang.translate('display_name')),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.isBusy ? null : () async {
                        final success = await vm.updateProfile(nameController.text);
                        if (success && context.mounted) Navigator.pop(context);
                      },
                      child: vm.isBusy ? const CircularProgressIndicator() : Text(lang.translate('save_changes')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedContainer(BuildContext context, {required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}