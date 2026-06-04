import 'package:animate_do/animate_do.dart';
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

    final percentage = goal.targetAmount > 0 
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) 
        : 0.0;

    const baseDuration = Duration(milliseconds: 600);
    const baseCurve = Curves.easeOutQuint;

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
          FadeInUp(
            duration: baseDuration,
            curve: baseCurve,
            delay: Duration.zero,
            child: _ChartHeader(lang: lang),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: FadeInUp(
                  duration: baseDuration,
                  curve: baseCurve,
                  delay: const Duration(milliseconds: 150),
                  child: _DoughnutChart(
                    goal: goal,
                    percentage: percentage,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 6,
                child: FadeInUp(
                  duration: baseDuration,
                  curve: baseCurve,
                  delay: const Duration(milliseconds: 300),
                  child: _ChartLegend(
                    goal: goal,
                    lang: lang,
                  ),
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
    return Text(
      lang.translate('goal_progress'),
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _DoughnutChart extends StatefulWidget {
  final SavingsGoal goal;
  final double percentage;

  const _DoughnutChart({required this.goal, required this.percentage});

  @override
  State<_DoughnutChart> createState() => _DoughnutChartState();
}

class _DoughnutChartState extends State<_DoughnutChart> with SingleTickerProviderStateMixin {
  late AnimationController _radialController;
  late Animation<double> _radialAnimation;

  @override
  void initState() {
    super.initState();
    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Elegant, relaxed loading speed
    );

    _radialAnimation = CurvedAnimation(
      parent: _radialController,
      curve: Curves.fastOutSlowIn,
    );

    // Run clockwise animation interpolation layout immediately on build
    _radialController.forward();
  }

  @override
  void dispose() {
    _radialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return SizedBox(
      height: 140,
      child: AnimatedBuilder(
        animation: _radialAnimation,
        builder: (context, child) {
          // Animate data targets based on the current interpolation progress
          final animatedCurrent = widget.goal.currentAmount * _radialAnimation.value;
          final remainingValue = (widget.goal.targetAmount - animatedCurrent).clamp(0.001, double.infinity);

          return Stack(
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 46,
                  startDegreeOffset: -90, // Places the start of the sweep perfectly at 12 o'clock
                  sections: [
                    PieChartSectionData(
                      value: animatedCurrent <= 0 ? 0.01 : animatedCurrent,
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.secondary],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      radius: 14,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: remainingValue,
                      color: colors.primary.withValues(alpha: 0.12),
                      radius: 14,
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
                      '${((widget.percentage * _radialAnimation.value) * 100).toStringAsFixed(0)}%',
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
          );
        },
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
        const SizedBox(height: 16),
        _LegendItem(
          label: lang.translate('saved'),
          value: goal.currentAmount,
          color: colors.primary,
        ),
        const SizedBox(height: 14),
        _LegendItem(
          label: lang.translate('remaining'),
          value: (goal.targetAmount - goal.currentAmount).clamp(0, double.infinity),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 28, 
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 1),
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