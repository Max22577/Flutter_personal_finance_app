import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:provider/provider.dart';


class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool showDefaultActions;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final bool automaticallyImplyLeading;
  final Color? textColor;
  final Widget? leading;

  const TopNavbar({
    super.key,
    this.showDefaultActions = true,
    this.backgroundColor,
    this.elevation = 7,
    this.shadowColor = Colors.black38,
    this.automaticallyImplyLeading = true,
    this.textColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();
  

    List<Widget> actionsToShow;
    if (navigationProvider.currentActions.isNotEmpty) {
      actionsToShow = navigationProvider.currentActions;
    } else {
      actionsToShow = _defaultActions(context);
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: theme.brightness == Brightness.light ? 0.08 : 0.3),
            blurRadius: elevation ?? 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            lang.translate(navigationProvider.currentTitle),
            key: ValueKey(navigationProvider.currentTitle), 
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onPrimary,
            ),
          ),
        ),
        backgroundColor: colors.primary,
        elevation: 0,
        centerTitle: true, 
        surfaceTintColor: Colors.transparent,
        leading: leading,
        iconTheme: IconThemeData(color: colors.onPrimary),
        automaticallyImplyLeading: automaticallyImplyLeading,
        actions: actionsToShow,
      ),
    );
  }

  List<Widget> _defaultActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications coming soon!')),
          );
        },
        tooltip: 'Notifications',
      ),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}