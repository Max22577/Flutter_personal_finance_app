import 'package:flutter/material.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';

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

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: textScaler.scale(160)),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Gradient background
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
            /// Decorative highlight (glass reflection effect)
           _buildDecorations(colors),

            /// Card content
            Padding(
              padding: EdgeInsets.all(textScaler.scale(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Row
                  Row(
                    children: [
                      _buildIconBadge(textScaler),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Currency Display
                  // FittedBox prevents text from wrapping or clipping if it's too long
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: CurrencyDisplay(
                      amount: amount,
                      compact: false,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge(TextScaler textScaler) {
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

  Widget _buildDecorations(ColorScheme colors) {
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