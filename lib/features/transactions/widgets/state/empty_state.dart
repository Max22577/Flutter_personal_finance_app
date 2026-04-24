import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EmptyState extends StatefulWidget {
  final String title;
  final String message;
  final bool isActive;
    
  const EmptyState({
    super.key,
    this.title = 'No transactions yet',
    this.message = 'Tap + to add your first transaction',
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
    final colors = theme.colorScheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
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
            Opacity(
              opacity: isDark ? 0.4 : 1.0, 
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colors.surfaceContainerLow.withValues(alpha: isDark ? 0.15 : 0.05),
                  BlendMode.srcATop,
                ),
                child: SvgPicture.asset(
                  isDark 
                  ? 'assets/images/trans_wallet_dark.svg' 
                  : 'assets/images/trans_wallet_light1.svg',
                  height: 150,
                ),
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