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
  final bool isOverGradient;
  

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.isRootNav = false,
    this.automaticallyImplyLeading = true,
    this.isOverGradient = false,
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
          : _defaultActions(context, colors);
    } else {
      displayTitle = title != null ? lang.translate(title!) : '';
      displayActions = actions ?? [];
    }

    final contentColor = isOverGradient ? colors.onPrimary : colors.onSurface;

    return AppBar(
      centerTitle: isRootNav, 
      title: isRootNav 
        ? AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              displayTitle,
              key: ValueKey(displayTitle),
              style: _titleStyle(theme, contentColor),
            ),
          )
        : Text(displayTitle, style: _titleStyle(theme, contentColor)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading,
      iconTheme: IconThemeData(color: contentColor),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: displayActions,
    );
    
  }

  TextStyle _titleStyle(ThemeData theme, Color colors) {
    return theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.bold,
      color: colors,
      letterSpacing: 0.5, 
    );
  }

  List<Widget> _defaultActions(BuildContext context, ColorScheme colors) {
    final iconBgColor = isOverGradient 
      ? Colors.white.withValues(alpha: 0.15)
      : colors.onSurface.withValues(alpha: 0.05);

    return [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          icon: Icon(Icons.notifications_outlined, color: isOverGradient ? colors.onPrimary : colors.onSurface,),
          style: IconButton.styleFrom(
            backgroundColor: iconBgColor,
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