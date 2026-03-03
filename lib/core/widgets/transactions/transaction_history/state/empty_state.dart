import 'package:flutter/material.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';

class EmptyState extends StatefulWidget {
  final String title;
  final String message;
  final String imagePath;
  final bool isActive;
    
  const EmptyState({
    super.key,
    this.title = 'No transactions yet',
    this.message = 'Tap + to add your first transaction',
    this.imagePath = 'assets/images/undraw_wallet_diag.png',
    this.isActive = false,
    
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), 
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant EmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0); 
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reset(); 
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final illustrationTheme = theme.extension<IllustrationTheme>();
    
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                illustrationTheme?.tintColor ?? Colors.transparent,
                illustrationTheme?.blendMode ?? BlendMode.srcIn,
              ),
              child: Image.asset(
                widget.imagePath,
                width: 250, // Adjust size as needed
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),           
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}