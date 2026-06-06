import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';
import 'package:provider/provider.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_card.dart';
import 'widgets/edit_profile_bottom_sheet.dart';

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
  @override
  void initState() {
    super.initState();
    _setupAppBarActions();
  }

  void _setupAppBarActions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vm = context.read<ProfileViewModel>();
        context.read<NavigationProvider>().setActions(3, [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Profile Settings',
            onPressed: () => _openEditProfileSheet(context, vm),
          ),
        ]);
      }
    });
  }

  void _openEditProfileSheet(BuildContext context, ProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileBottomSheet(viewModel: vm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                ProfileHeader(
                  fullName: vm.fullName ?? '',
                  email: vm.authEmail,
                  photoUrl: vm.photoUrl,
                ),
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: 'Settings'),
                      SizedBox(height: 12),
                      SettingsCard(),
                    ],
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
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
    );
  }
}