import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/currency_display.dart';
import 'package:personal_fin/features/savings/widgets/add_to_savings_button.dart';
import 'package:provider/provider.dart';
import '../../../models/savings.dart';

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
    
    // 2. Uniform colors for both chart and legend
    final Color progressColor = colors.primary;
    final Color trackColor = colors.primary.withValues(alpha: 0.15); // Soft matching background track
    
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
              _buildHeader(theme, colors, lang),
              const SizedBox(height: 24),
              Row(
                children: [
                  // --- Doughnut Chart ---
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 140,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 50, // Increased for a thin ring look
                              startDegreeOffset: -90,
                              sections: [
                                PieChartSectionData(
                                  value: goal.currentAmount == 0 ? 0.01 : goal.currentAmount,
                                  gradient: LinearGradient(
                                    colors: [
                                      colors.primary, 
                                      colors.secondary,
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                  radius: 16, // Thicker ring
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: (goal.targetAmount - goal.currentAmount) <= 0 
                                    ? 0.001 
                                    : (goal.targetAmount - goal.currentAmount),
                                  color: trackColor,
                                  radius: 16, // Smaller ring
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
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // --- Legend Section ---
                  Expanded(
                    flex: 6,
                    child: Column(
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
                        // Saved (Shows current progress)
                        _buildLegendItem(
                          label: lang.translate('saved'), 
                          value: goal.currentAmount, 
                          color: progressColor, 
                          theme: theme
                        ),
                        const SizedBox(height: 12),

                        // Remaining (Shows what's left)
                        _buildLegendItem(
                          label: lang.translate('remaining'), 
                          value: goal.targetAmount - goal.currentAmount, 
                          color: trackColor, 
                          theme: theme
                        ),
                        const SizedBox(height: 20),

                        // Add To Savings Button 
                        AddToSavingsButton(goal: goal),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors, LanguageProvider lang) {
    return Row(
      children: [
        Icon(Icons.auto_graph_rounded, color: colors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          lang.translate('goal_progress'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required String label, 
    required double value, 
    required Color color, 
    required ThemeData theme
  }) {
    return Row(
      children: [
        Container(
          width: 8, 
          height: 8, 
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)
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