import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AnimatedEmptyChart extends StatefulWidget {
  final String message;
  const AnimatedEmptyChart({super.key, required this.message});

  @override
  State<AnimatedEmptyChart> createState() => _AnimatedEmptyChartState();
}

class _AnimatedEmptyChartState extends State<AnimatedEmptyChart> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // This makes it oscillate back and forth

    // Semi-rotation: -0.1 to 0.1 radians (roughly -6 to 6 degrees)
    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: child,
            );
          },

          child: Opacity(
            // In Dark Mode, we lower the total visibility of the bright image 
            // so it doesn't "glow" against the dark surface.
            opacity: isDark ? 0.4 : 1.0, 
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                // We use the surface color to "stain" the image
                colors.surfaceContainerHigh.withValues(alpha: isDark ? 0.15 : 0.05),
                BlendMode.srcATop,
              ),
              child: SvgPicture.asset(
                isDark 
                ? 'assets/images/empty_wallet_dark1.svg' 
                : 'assets/images/empty_wallet_light.svg',
                height: 150,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.message,
          style: TextStyle(
            color: colors.outline,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  
}