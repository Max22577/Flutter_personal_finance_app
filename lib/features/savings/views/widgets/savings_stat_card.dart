import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/features/savings/view_models/savings_view_model.dart';
import 'package:provider/provider.dart';

class SavingsStatCard extends StatelessWidget {
  final SavingsState state;

  const SavingsStatCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            lang.translate('savings_overview'),
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 2x2 Grid with precise cross-axis and main-axis gaps
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.4, // Prevents text overflow while maintaining card proportions
          mainAxisSpacing: 12,   // Controlled vertical spacing
          crossAxisSpacing: 12,  // Controlled horizontal spacing
          children: [
            _StatCardItem(
              label: lang.translate('goals'),
              icon: Icons.flag_rounded,
              iconColor: colors.primary,
              valueWidget: Text(
                state.goals.length.toString(),
                style: _valueStyle(textTheme, colors.onSurface),
              ),
            ),
            _StatCardItem(
              label: lang.translate('progress'),
              icon: Icons.ads_click_rounded,
              iconColor: colors.tertiary,
              valueWidget: Text(
                '${(state.overallProgress * 100).toStringAsFixed(0)}%',
                style: _valueStyle(textTheme, colors.tertiary),
              ),
            ),
            _StatCardItem(
              label: lang.translate('target'),
              icon: Icons.track_changes_rounded,
              iconColor: colors.secondary,
              valueWidget: CurrencyDisplay(
                amount: state.totalTarget,
                compact: true,
                style: _valueStyle(textTheme, colors.onSurface),
              ),
            ),
            _StatCardItem(
              label: lang.translate('saved'),
              icon: Icons.savings_rounded,
              iconColor: colors.primary,
              valueWidget: CurrencyDisplay(
                amount: state.totalSaved,
                compact: true,
                style: _valueStyle(textTheme, colors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  TextStyle _valueStyle(TextTheme textTheme, Color color) => textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: color,
      );
}

// Private sub-component card unit
class _StatCardItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget valueWidget;

  const _StatCardItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Row: Top Left Mini Tinted Decorative Icon Badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          
          // Bottom Column: Metrics and Title stacked cleanly
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              valueWidget,
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  fontSize: 10,
                  color: colors.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}