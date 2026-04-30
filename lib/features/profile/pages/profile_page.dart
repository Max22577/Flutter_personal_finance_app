import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:provider/provider.dart';
import '../view_models/profile_view_model.dart';

class ProfilePage extends StatelessWidget {
  final ProfileViewModel? viewModel;
  const ProfilePage({super.key, this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => viewModel ?? ProfileViewModel(),
      child: const ProfileViewContent(),
    );
  }
}

class ProfileViewContent extends StatefulWidget {
  const ProfileViewContent({super.key});

  @override
  State<ProfileViewContent> createState() => _ProfileViewContentState();
}

class _ProfileViewContentState extends State<ProfileViewContent> {
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late NavigationProvider? _navigationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAppBar();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _navigationProvider = context.read<NavigationProvider>();
      _navigationProvider?.addListener(_onNavChanged); 
    } catch (e) {
      debugPrint('NavigationProvider not found: $e');
    }
  }

  void _onNavChanged() {
    if (!mounted || _navigationProvider == null) return;
    
    if (_navigationProvider!.selectedIndex == 3 && _navigationProvider!.currentActions.isEmpty) {
      _updateAppBar();
    } 
  }

  void _updateAppBar() {
    if (!mounted || _navigationProvider == null) return;

    if (_navigationProvider!.selectedIndex == 3) {
      _navigationProvider!.setActions([
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              shape: const CircleBorder(),
            ),
            onPressed: () => context.read<ProfileViewModel>().signOut(),
          ),
        )
      ]);
    }

  }

  @override
  void dispose() {
    if (_navigationProvider != null) {
      _navigationProvider!.removeListener(_onNavChanged);
    }
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Sync controllers with VM data when it loads
    if (!vm.isLoading && _fullNameController.text.isEmpty) {
      _fullNameController.text = vm.fullName ?? '';
      _bioController.text = vm.bio ?? '';
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: vm.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, colors, theme, vm),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(theme, lang.translate('account_security')),
                        _buildInfoTile(Icons.email, lang.translate('email'), vm.authEmail, theme.colorScheme),
                        const SizedBox(height: 24),
                        _buildSectionHeader(theme, lang.translate('public_details')),
                        _buildTextField(
                          controller: _fullNameController,
                          label: lang.translate('display_name'),
                          icon: Icons.badge,
                          theme: theme,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _bioController,
                          label: lang.translate('short_bio'),
                          icon: Icons.auto_awesome,
                          theme: theme,
                          isBio: true,
                        ),
                        const SizedBox(height: 30),
                        _buildSaveButton(context, vm, lang, colors, textTheme),
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
  Widget _buildHeader(BuildContext context, ColorScheme colors, ThemeData theme, ProfileViewModel vm) {
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
          _buildAvatar(context, colors, vm),
          const SizedBox(height: 16),
          Text(
            _fullNameController.text.isEmpty ? 'Your Profile' : _fullNameController.text,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            vm.authEmail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Refined Avatar with Edit Overlay
  Widget _buildAvatar(BuildContext context, ColorScheme colors, ProfileViewModel vm) {
    final messenger = ScaffoldMessenger.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: colors.surfaceContainerHigh,
            backgroundImage: vm.photoUrl != null 
                ? NetworkImage(vm.photoUrl!) 
                : null,
            child: vm.photoUrl == null 
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
                onPressed: () => AppFeedback.show(messenger, 'Image upload coming soon!', colors: colors, textTheme: textTheme, isError: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          Expanded(
            child: Column(
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
          ),
          const Spacer(),
          Icon(Icons.lock_outline, size: 18, color: colors.outline),
        ],
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

  Widget _buildSaveButton(BuildContext context, ProfileViewModel vm, LanguageProvider lang, ColorScheme colors, TextTheme textTheme) {
    final messenger = ScaffoldMessenger.of(context);
    return ElevatedButton(
      onPressed: vm.isLoading ? null : () async {
        try {
          await vm.updateProfile(
            name: _fullNameController.text, 
            newBio: _bioController.text,
          );
          if (!mounted) return;
          AppFeedback.show(messenger, lang.translate('profile_updated'), colors: colors, textTheme: textTheme, isError: false);
        } catch (e) {
          AppFeedback.show(messenger, e.toString(), colors: colors, textTheme: textTheme, isError: true);
        }
      },
      child: vm.isLoading 
        ? const CircularProgressIndicator() 
        : Text(lang.translate('save_changes')),
    );
  }

}