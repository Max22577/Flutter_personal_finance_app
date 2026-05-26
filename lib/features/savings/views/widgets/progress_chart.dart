import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/features/savings/views/widgets/add_to_savings_button.dart';
import 'package:provider/provider.dart';
import '../../../../models/savings.dart';

class ProgressChartWidget extends StatelessWidget {
  final SavingsGoal goal;

  const ProgressChartWidget({required this.goal, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    final percentage = goal.targetBaseAmount > 0 
        ? (goal.currentBaseAmount / goal.targetBaseAmount).clamp(0.0, 1.0) 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(lang: lang),
          const SizedBox(height: 24),
          Row(
            children: [
              // --- Doughnut Chart ---
              Expanded(
                flex: 5,
                child: _DoughnutChart(
                  goal: goal,
                  percentage: percentage,
                ),
              ),
              const SizedBox(width: 24),
              // --- Legend Section ---
              Expanded(
                flex: 6,
                child: _ChartLegend(
                  goal: goal,
                  lang: lang,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _ChartHeader extends StatelessWidget {
  final LanguageProvider lang;

  const _ChartHeader({required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.auto_graph_rounded, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          lang.translate('goal_progress'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DoughnutChart extends StatelessWidget {
  final SavingsGoal goal;
  final double percentage;

  const _DoughnutChart({required this.goal, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 50,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: goal.currentBaseAmount <= 0 ? 0.01 : goal.currentBaseAmount,
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  radius: 16,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (goal.targetBaseAmount - goal.currentBaseAmount).clamp(0.001, double.infinity),
                  color: colors.primary.withValues(alpha: 0.15),
                  radius: 16,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  lang.translate('saved').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final SavingsGoal goal;
  final LanguageProvider lang;

  const _ChartLegend({required this.goal, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.name.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.0,
            fontWeight: FontWeight.w800,
            color: colors.outline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          label: lang.translate('saved'),
          value: goal.currentBaseAmount,
          color: colors.primary,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          label: lang.translate('remaining'),
          value: (goal.targetBaseAmount - goal.currentBaseAmount).clamp(0, double.infinity),
          color: colors.primary.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 20),
        AddToSavingsButton(goal: goal),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                ),
              ),
              CurrencyDisplay(
                amount: value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}