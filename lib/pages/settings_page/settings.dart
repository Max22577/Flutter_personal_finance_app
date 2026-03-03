import 'dart:io';
import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/settings_page/profile_card.dart';
import 'package:personal_fin/pages/settings_page/appearance.dart';
import 'package:personal_fin/pages/settings_page/general_settings.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/settings_page/settings_section.dart';
import '../../models/setting_item.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  File? _selectedImage;
  
  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('${_user!.uid}.jpg');

      // Upload the file
      await storageRef.putFile(image);

      // Get the permanent download URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
  
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
  void _navigateToPage(String pageId) {
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
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('settings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onPrimary,
          ),
        ),
        backgroundColor: colors.primary,
        elevation: 0,
        centerTitle: true, 
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchSettings,
            tooltip: lang.translate('search_settings'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final lang = context.watch<LanguageProvider>();
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Card
          SimpleProfileCard(
            user: _user,
            onTap: _editProfile,
          ),

          // Settings Sections
          SettingsSection(
            title: lang.translate('personalization'),
            items: _getgeneralSettings(lang),
            onSettingTapped: (SettingItem item) {
              switch (item.id) {
                case 'appearance':
                  _navigateToPage('appearance');
                  break;
                case 'general':
                  _navigateToPage('general');
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
                _navigateToPage('notifications');
              }
            },
          ),

          SettingsSection(
            title: lang.translate('security_title'),
            subtitle: _user == null ? lang.translate('security_sign_in') : null,
            items: _getsecuritySettings(lang),
            onSettingTapped: (SettingItem item) {
              if (item.id == 'security') {
                _navigateToPage('security');
              }
            },
          ),

          SettingsSection(
            title: lang.translate('financial_planning'),
            items: _getbudgetSettings(lang),
            onSettingTapped: (SettingItem item) {
              if (item.id == 'budget') {
                _navigateToPage('budget');
              }
            },
          ),

          SettingsSection(
            title: lang.translate('data_mgmt_title'),
            subtitle: lang.translate('data_mgmt_sub'),
            items: _getdataSettings(lang),
            onSettingTapped: (SettingItem item) {
              if (item.id == 'data') {
                _navigateToPage('data');
              }
            },
          ),

          SettingsSection(
            title: lang.translate('about'),
            items: _getaboutSettings(lang),
            onSettingTapped: (SettingItem item) {
              if (item.id == 'about') {
                _navigateToPage('about');
              }
            },
          ),

          // Sign Out Button
          if (_user != null) _buildSignOutButton(),

          // App Info Footer
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    final lang = context.watch<LanguageProvider>();

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
          onPressed: _signOut,
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'FinManager v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 FinManager. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedContainer({required Widget child}) {
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

  // Action Methods
  void _editProfile() {
    final nameController = TextEditingController(text: _user?.displayName);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    final lang = context.read<LanguageProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( 
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _buildFrostedContainer(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHandleBar(),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setSheetState(() => _selectedImage = File(pickedFile.path));
                      }
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null 
                              ? FileImage(_selectedImage!) 
                              : (_user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null) as ImageProvider?,
                          child: _selectedImage == null && _user?.photoURL == null 
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
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: lang.translate('display_name'),
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? lang.translate('name_cannot_be_empty') : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (formKey.currentState!.validate()) {
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final theme = Theme.of(context);

                          setSheetState(() => isSaving = true);
                          String? photoUrl = _user?.photoURL;

                          // 1. Upload to Storage if a new image was picked
                          if (_selectedImage != null) {
                            photoUrl = await _uploadImage(_selectedImage!);
                          }

                          try {
                            // 1. Update Firebase Auth
                            await _user?.updateDisplayName(nameController.text.trim());
                            await _user?.updatePhotoURL(photoUrl);
                            // 2. Refresh the local user object
                            await _user?.reload();
                            
                            if (mounted) {
                              navigator.pop(); 
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(lang.translate('profile_updated_successfully'),
                                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)
                                  ),
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  margin: const EdgeInsets.all(20),
                                ),
                              );
                              setState(() {}); 
                            }
                          } catch (e) {
                            setSheetState(() => isSaving = false);
                            debugPrint('Error updating profile: $e');
                          }
                        }
                      },
                      child: isSaving 
                        ? const CircularProgressIndicator() 
                        : Text(lang.translate('save_changes')),
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

  void _searchSettings() {
    debugPrint('Search settings');
  }

  void _signOut() async {
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

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}