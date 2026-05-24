import 'package:flutter/material.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';

class MainBudgetStat extends StatelessWidget {
  final String label;
  final double amount;

  const MainBudgetStat({
    super.key,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Hero(
      tag: 'main_budget_hero',
      child: GlassStatCard(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatHeader(
              label: label,
              textScaler: textScaler,
              textTheme: theme.textTheme,
            ),
            const SizedBox(height: 16),
            
            _StatAmount(
              amount: amount,
              displayStyle: theme.textTheme.displaySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatHeader extends StatelessWidget {
  final String label;
  final TextScaler textScaler;
  final TextTheme textTheme;

  const _StatHeader({
    required this.label,
    required this.textScaler,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBadge(textScaler: textScaler),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final TextScaler textScaler;

  const _IconBadge({required this.textScaler});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        color: Colors.white,
        size: textScaler.scale(20).clamp(18, 28),
      ),
    );
  }
}

class _StatAmount extends StatelessWidget {
  final double amount;
  final TextStyle? displayStyle;

  const _StatAmount({
    required this.amount,
    required this.displayStyle,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: CurrencyDisplay(
        baseAmount: amount,
        compact: false,
        style: displayStyle?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class GlassStatCard extends StatelessWidget {
  final Widget child;
  final ColorScheme colors;
  final double minHeight;

  const GlassStatCard({
    super.key,
    required this.child,
    required this.colors,
    this.minHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: textScaler.scale(minHeight)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.9),
            colors.primaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const _CardDecorativeBubbles(),
            Padding(
              padding: EdgeInsets.all(textScaler.scale(24)),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDecorativeBubbles extends StatelessWidget {
  const _CardDecorativeBubbles();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide;
          return Stack(
            children: [
              Positioned(
                right: -size * 0.2,
                top: -size * 0.3,
                child: CircleAvatar(
                  radius: size * 0.4,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                right: size * 0.1,
                bottom: -size * 0.4,
                child: CircleAvatar(
                  radius: size * 0.3,
                  backgroundColor: Colors.black.withValues(alpha: 0.03),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}