import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
import 'package:personal_fin/features/savings/view_models/savings_view_model.dart';
import 'package:provider/provider.dart';

class SavingsStatCard extends StatelessWidget {
  final SavingsViewModel vm;

  const SavingsStatCard({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    final lang = context.watch<LanguageProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Icon and Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.insights_rounded, color: colors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  lang.translate('savings_overview'),
                  style: textTheme.labelMedium?.copyWith( 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row with Dividers
          IntrinsicHeight( // Ensures vertical dividers match column height
            child: Column(
              children: [
                Row(
                  children: [
                    _StatItem(label: lang.translate('goals'), valueWidget: Text(vm.goals.length.toString(), style: _valueStyle(textTheme)), theme: theme),
                    _VerticalDivider(colors: colors),
                    _StatItem(label: lang.translate('progress'), valueWidget: Text('${(vm.overallProgress * 100).toStringAsFixed(0)}%', 
                        style: _valueStyle(textTheme).copyWith(color: colors.primary)), theme: theme),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: colors.outlineVariant.withValues(alpha: 0.1)),
                ),
                Row(
                  children: [
                    _StatItem(label: lang.translate('target'), valueWidget: CurrencyDisplay(baseAmount: vm.totalTargetBase, compact: true, style: _valueStyle(textTheme)), theme: theme),
                    _VerticalDivider(colors: colors),
                    _StatItem(label: lang.translate('saved'), valueWidget: CurrencyDisplay(baseAmount: vm.totalSavedBase, compact: true, style: _valueStyle(textTheme)), theme: theme),
                  ],
                ),
              ],
            )
          ),
        ],
      ),
    );
  }

  TextStyle _valueStyle(TextTheme textTheme) => textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );  
}

class _StatItem extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  final ThemeData theme;

  const _StatItem({required this.label, required this.valueWidget, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded( 
      child: Column(
        children: [
          valueWidget,
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 9,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final ColorScheme colors;

  const _VerticalDivider({required this.colors});

   @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      color: colors.outlineVariant.withValues(alpha: 0.2),
      thickness: 1,
      indent: 8,
      endIndent: 8,
    );
  }
}