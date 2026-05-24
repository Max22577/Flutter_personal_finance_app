import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title; 
  final List<Widget>? actions; 
  final Widget? leading;
  final bool isRootNav; 
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.isRootNav = false,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    // Determine Title and Actions dynamically
    String displayTitle = '';
    List<Widget> displayActions = [];

    if (isRootNav) {
      final navProvider = Provider.of<NavigationProvider>(context);
      displayTitle = lang.translate(navProvider.currentTitle);
      displayActions = navProvider.currentActions.isNotEmpty
          ? navProvider.currentActions
          : _defaultActions(context);
    } else {
      displayTitle = title != null ? lang.translate(title!) : '';
      displayActions = actions ?? [];
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, 0.6)!,
            colors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AppBar(
            // Material 3 defaults to false (left-aligned) on sub-pages
            centerTitle: isRootNav, 
            title: isRootNav 
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    displayTitle,
                    key: ValueKey(displayTitle),
                    style: _titleStyle(theme, colors),
                  ),
                )
              : Text(displayTitle, style: _titleStyle(theme, colors)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: leading,
            iconTheme: IconThemeData(color: colors.onPrimary),
            automaticallyImplyLeading: automaticallyImplyLeading,
            actions: displayActions,
          ),
        ),
      ),
    );
  }

  TextStyle _titleStyle(ThemeData theme, ColorScheme colors) {
    return theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.bold,
      color: colors.onPrimary,
      letterSpacing: 0.5, 
    );
  }

  List<Widget> _defaultActions(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            shape: const CircleBorder(),
          ),
          onPressed: () {},
        ),
      ),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}