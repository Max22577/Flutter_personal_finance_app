import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';
import 'package:provider/provider.dart';

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
  late final TextEditingController _fullNameController;
  late final TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();
  late NavigationProvider _navProvider;

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();
    _fullNameController = TextEditingController(text: vm.fullName);
    _bioController = TextEditingController(text: vm.bio);

    // Initial setup of AppBar
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAppBar());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navProvider = context.read<NavigationProvider>();
    _navProvider.removeListener(_onNavChanged);
    _navProvider.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (!mounted) return;
    if (_navProvider.selectedIndex == 3 && _navProvider.currentActions.isEmpty) {
      _updateAppBarLogic();
    }
  }

  void _initAppBar() {
    if (mounted && _navProvider.selectedIndex == 3) {   
      _updateAppBarLogic();
    }
  }

  void _updateAppBarLogic() {
    final vm = context.read<ProfileViewModel>();
    _ProfileActionsHandler.setProfileActions(context, _navProvider, vm); 
  }

  @override
  void dispose() {
    _navProvider.removeListener(_onNavChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navProvider.setActions([]);
    });
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final colors = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: vm.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView( // Changed to ListView for better scroll physics
              children: [
                _ProfileHeader(
                  fullName: _fullNameController.text,
                  email: vm.authEmail,
                  photoUrl: vm.photoUrl,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _SectionHeader(title: lang.translate('account_security')),
                        _InfoSection(email: vm.authEmail),
                        const SizedBox(height: 24),
                        _PublicDetailsSection(
                          nameController: _fullNameController,
                          bioController: _bioController,
                        ),
                        const SizedBox(height: 32),
                        _SaveProfileButton(
                          vm: vm,
                          name: _fullNameController,
                          bio: _bioController,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileActionsHandler {
  static void setProfileActions(BuildContext context, NavigationProvider nav, ProfileViewModel vm) {
    nav.setActions([
      IconButton(
        icon: const Icon(Icons.logout_rounded),
        onPressed: () => vm.signOut(),
      ),
    ]);
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String? photoUrl;

  const _ProfileHeader({required this.fullName, required this.email, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
          _AvatarStack(photoUrl),
          const SizedBox(height: 16),
          Text(
            fullName.isEmpty ? 'Your Profile' : fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final String? photoUrl;

  const _AvatarStack(this.photoUrl);

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: colors.surfaceContainerHigh,
            backgroundImage: photoUrl != null 
                ? NetworkImage(photoUrl!) 
                : null,
            child: photoUrl == null 
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
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String email;

  const _InfoSection({required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

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
          Icon(Icons.email, color: colors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.translate('email'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
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
}

class _PublicDetailsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController? bioController;

  const _PublicDetailsSection({required this.nameController, this.bioController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();

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
        controller: nameController,
        maxLines: bioController != null ? 4 : 1,
        decoration: InputDecoration(
          labelText: lang.translate('display_name'),
          prefixIcon: Icon(Icons.badge, color: theme.colorScheme.primary),
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
}

class _SaveProfileButton extends StatelessWidget {
  final ProfileViewModel vm;
  final TextEditingController name;
  final TextEditingController bio;

  const _SaveProfileButton({required this.vm, required this.name, required this.bio});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: vm.isLoading ? null : () => vm.updateProfile(name: name.text, newBio: bio.text),
      child: vm.isLoading ? CircularProgressIndicator() : Text('Save'),
    );
  }
}