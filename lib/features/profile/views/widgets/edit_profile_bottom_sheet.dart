import 'package:flutter/material.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';

class EditProfileBottomSheet extends StatefulWidget {
  final ProfileViewModel viewModel;
  const EditProfileBottomSheet({super.key, required this.viewModel});

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.viewModel.fullName);
    _bioController = TextEditingController(text: widget.viewModel.bio);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Edit Profile', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _InfoTile(email: widget.viewModel.authEmail),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.badge_rounded)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.notes_rounded), alignLabelWithHint: true),
              ),
              const SizedBox(height: 32),
              ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: widget.viewModel.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                await widget.viewModel.updateProfile(
                                  name: _fullNameController.text,
                                  newBio: _bioController.text,
                                );
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                      child: widget.viewModel.isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String email;
  const _InfoTile({required this.email});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: colors.outline),
          const SizedBox(width: 12),
          Text(email, style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}