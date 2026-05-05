import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum EmptyStateAnimation { rotate, bounce, fade, scale }

class AnimatedEmptyState extends StatefulWidget {
  final String message;
  final String imagePath;
  final String? darkImagePath; 
  final EmptyStateAnimation animationType;
  final double imageHeight;

  const AnimatedEmptyState({
    super.key,
    required this.message,
    required this.imagePath,
    this.darkImagePath,
    this.animationType = EmptyStateAnimation.rotate, 
    this.imageHeight = 150,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // build the tween based on the animationType passed in
    _animation = _buildAnimation();
  }

  Animation<double> _buildAnimation() {
    switch (widget.animationType) {
      case EmptyStateAnimation.bounce:
        return Tween<double>(begin: 0.0, end: -15.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
      case EmptyStateAnimation.scale:
        return Tween<double>(begin: 0.95, end: 1.05).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
      case EmptyStateAnimation.rotate:
      default:
        return Tween<double>(begin: -0.1, end: 0.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return _applyAnimationEffect(child!);
          },
          child: Opacity(
            opacity: isDark ? 0.5 : 1.0,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                colors.surfaceContainerHigh.withValues(alpha: isDark ? 0.2 : 0.05),
                BlendMode.srcATop,
              ),
              child: SvgPicture.asset(
                (isDark && widget.darkImagePath != null) 
                    ? widget.darkImagePath! 
                    : widget.imagePath,
                height: widget.imageHeight,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.outline,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  /// Helper to wrap the child in the correct Transform/Effect widget
  Widget _applyAnimationEffect(Widget child) {
    switch (widget.animationType) {
      case EmptyStateAnimation.rotate:
        return Transform.rotate(angle: _animation.value, child: child);
      case EmptyStateAnimation.bounce:
        return Transform.translate(offset: Offset(0, _animation.value), child: child);
      case EmptyStateAnimation.scale:
        return Transform.scale(scale: _animation.value, child: child);
      case EmptyStateAnimation.fade:
        return Opacity(opacity: (0.6 + (_controller.value * 0.4)), child: child);
    }
  }
}