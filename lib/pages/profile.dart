import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:provider/provider.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _db = FirebaseFirestore.instance;

const String appId = String.fromEnvironment('app_id', defaultValue: 'default-app-id');

DocumentReference _getProfileDocRef(String userId) {
  return _db
      .collection('artifacts')
      .doc(appId)
      .collection('users')
      .doc(userId)
      .collection('profile_data')
      .doc('details_doc');
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _authEmail = 'Loading...';
  bool _isLoading = true;
  User? _currentUser;
  StreamSubscription? _profileSubscription;
  late NavigationProvider _navigationProvider;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _authEmail = _currentUser?.email ?? 'N/A';
    _loadProfileData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAppBar(context);
    });
  }


  void _loadProfileData() {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    _profileSubscription?.cancel();
    
    _profileSubscription = _getProfileDocRef(_currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          
          // Load full name with fallback
          _fullNameController.text = data['fullName'] ?? 
                                     _currentUser!.displayName ?? 
                                     '';
          
          // Load bio if exists
          _bioController.text = data['bio'] ?? '';
        } else {
          // Use Firebase Auth display name if no custom data
          _fullNameController.text = _currentUser!.displayName ?? '';
          _bioController.text = '';
        }
      });
    }, onError: (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load profile: $error', isError: true);
      }
    });
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isLoading = true);
    
    final String newFullName = _fullNameController.text.trim();
    final String newBio = _bioController.text.trim();

    try {
      await _getProfileDocRef(_currentUser!.uid).set({
        'fullName': newFullName,
        'bio': newBio,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _currentUser!.updateDisplayName(newFullName);

      _showSnackBar('Profile updated successfully!');
      
      setState(() => _isLoading = false);
      
      await _currentUser!.reload();
      
    } catch (e) {
      _showSnackBar('Error saving profile: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigationProvider = context.read<NavigationProvider>();
    _navigationProvider.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (!mounted) return;
    final nav = context.read<NavigationProvider>();
    
    if (nav.selectedIndex == 3 && nav.currentActions.isEmpty) {
      _updateAppBar(context);
    } 
  }

  void _updateAppBar(BuildContext context) {
      if (!mounted) return;
      final nav = context.read<NavigationProvider>();
      
      if (nav.selectedIndex == 3) {
        nav.setActions([
          IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _auth.signOut(), 
        )
        ]);
      }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _profileSubscription?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final nav = context.read<NavigationProvider>();

        nav.setActions([]);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(colors, theme),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader(theme, lang.translate('account_security')),
                      _buildInfoTile(Icons.alternate_email_rounded, lang.translate('email'), _authEmail, colors),
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader(theme, lang.translate('public_details')),
                      _buildTextField(
                        controller: _fullNameController,
                        label: lang.translate('display_name'),
                        icon: Icons.badge_outlined,
                        theme: theme,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _bioController,
                        label: lang.translate('short_bio'),
                        icon: Icons.auto_awesome_outlined,
                        theme: theme,
                        isBio: true,
                      ),
                      const SizedBox(height: 30),
                      _buildSaveButton(theme),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  // 1. Beautiful Header with overlapping Avatar
  Widget _buildHeader(ColorScheme colors, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: colors.surface, 
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.primary.withValues(alpha: 0.05), 
            colors.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          _buildAvatar(colors),
          const SizedBox(height: 16),
          Text(
            _fullNameController.text.isEmpty ? 'Your Profile' : _fullNameController.text,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            _authEmail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Refined Avatar with Edit Overlay
  Widget _buildAvatar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: colors.surfaceContainerHighest,
            backgroundImage: _currentUser?.photoURL != null 
                ? NetworkImage(_currentUser!.photoURL!) 
                : null,
            child: _currentUser?.photoURL == null 
                ? Icon(Icons.person_rounded, size: 70, color: colors.outline) 
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: CircleAvatar(
              backgroundColor: colors.primary,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                onPressed: () => _showSnackBar('Image upload coming soon!'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Helper for Form Sections
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool isBio = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: isBio ? 4 : 1,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline, size: 18, color: colors.outline),
        ],
      ),
    );
  }
  Widget _buildSaveButton(ThemeData theme) {
    final colors = theme.colorScheme;
    final lang = context.read<LanguageProvider>();
    
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfileData,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        elevation: 0,
        shadowColor: colors.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _isLoading
        ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline),
            SizedBox(width: 10),
            Text(
              lang.translate('save_changes'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
    );
  }
}