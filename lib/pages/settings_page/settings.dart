import 'dart:io';
import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:personal_fin/core/widgets/settings_page/profile_card.dart';
import 'package:personal_fin/pages/settings_page/appearance.dart';
import 'package:personal_fin/pages/settings_page/general_settings.dart';
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
  List<SettingItem> get _generalSettings => [
    SettingItem(
      id: 'appearance',
      title: 'Appearance',
      subtitle: 'Theme, colors, display',
      icon: Icons.color_lens,
      type: SettingType.navigation,
    ),
    SettingItem(
      id: 'general',
      title: 'General Settings',
      subtitle: 'Currency, language, units',
      icon: Icons.settings,
      type: SettingType.navigation,
    ),
  ];

  List<SettingItem> get _notificationSettings => [
    SettingItem(
      id: 'notifications',
      title: 'Notifications',
      subtitle: 'Push, email, reminders',
      icon: Icons.notifications,
      type: SettingType.navigation,
    ),
    SettingItem(
      id: 'push_enabled',
      title: 'Push Notifications',
      subtitle: 'Alerts for overspending',
      icon: Icons.notifications_active,
      type: SettingType.toggle, // Changed to toggle
      value: true, 
    ),
  ];

  List<SettingItem> get _securitySettings => [
    SettingItem(
      id: 'security',
      title: 'Security',
      subtitle: 'Login, privacy, data protection',
      icon: Icons.security,
      type: SettingType.navigation,
    ),
  ];

  List<SettingItem> get _budgetSettings => [
    SettingItem(
      id: 'budget',
      title: 'Budget & Goals',
      subtitle: 'Monthly budget, savings targets',
      icon: Icons.account_balance_wallet,
      type: SettingType.navigation,
    ),
  ];

  List<SettingItem> get _dataSettings => [
    SettingItem(
      id: 'data',
      title: 'Data Management',
      subtitle: 'Backup, export, clear data',
      icon: Icons.storage,
      type: SettingType.navigation,
    ),
    SettingItem(
      id: 'export_csv',
      title: 'Export Data',
      subtitle: 'Download your history as CSV',
      icon: Icons.file_download,
      type: SettingType.action, 
    ),
    SettingItem(
      id: 'delete_account',
      title: 'Delete Account',
      subtitle: 'Permanently remove all data',
      icon: Icons.delete_forever,
      type: SettingType.destructive, // Changed to destructive
    ),
  ];

  List<SettingItem> get _aboutSettings => [
    SettingItem(
      id: 'about',
      title: 'About & Legal',
      subtitle: 'App info, privacy, terms',
      icon: Icons.info,
      type: SettingType.navigation,
    ),
  ];

  // Navigation handlers
  void _navigateToPage(String pageId) {
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
          content: Text('page coming soon!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
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
            tooltip: 'Search Settings',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
            title: 'Personalization',
            items: _generalSettings,
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
            title: 'Alerts & Notifications',
            items: _notificationSettings,
            onSettingTapped: (SettingItem item) {
              if (item.id == 'notifications') {
                _navigateToPage('notifications');
              }
            },
          ),

          SettingsSection(
            title: 'Security',
            subtitle: _user == null ? 'Sign in to enable security features' : null,
            items: _securitySettings,
            onSettingTapped: (SettingItem item) {
              if (item.id == 'security') {
                _navigateToPage('security');
              }
            },
          ),

          SettingsSection(
            title: 'Financial Planning',
            items: _budgetSettings,
            onSettingTapped: (SettingItem item) {
              if (item.id == 'budget') {
                _navigateToPage('budget');
              }
            },
          ),

          SettingsSection(
            title: 'Data',
            items: _dataSettings,
            onSettingTapped: (SettingItem item) {
              if (item.id == 'data') {
                _navigateToPage('data');
              }
            },
          ),

          SettingsSection(
            title: 'About',
            items: _aboutSettings,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
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
                  Text('Edit Profile', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
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
                                  content: Text('Profile updated successfully!',
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
                        : const Text('Save Changes'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}