import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String? photoUrl;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.email,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          _AvatarStack(photoUrl: photoUrl, onEditPressed: () => {}),
          const SizedBox(height: 16),
          Text(
            fullName.isEmpty ? 'Your Profile' : fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
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
  final VoidCallback? onEditPressed; 

  const _AvatarStack({this.photoUrl, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Main Avatar Container
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: colors.surfaceContainerHigh,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null 
                ? Icon(Icons.person_rounded, size: 60, color: colors.outline) 
                : null,
          ),
        ),
        
        // Camera Icon Overlay
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEditPressed,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 3),
              ),
              child: Icon(
                Icons.camera_alt_rounded, 
                size: 20, 
                color: colors.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}