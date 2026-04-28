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
    
    final Color progressColor = colors.primary;
    final Color trackColor = colors.onSurfaceVariant.withValues(alpha: 0.1); 
    
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, colors, lang),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Doughnut Chart ---
                  Expanded(
                    flex: 4,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: double.infinity, // Remove center space for a full pie
                              startDegreeOffset: -90,
                              sections: [
                                PieChartSectionData(
                                  value: goal.currentAmount == 0 ? 0.01 : goal.currentAmount,
                                  gradient: LinearGradient(
                                    colors: [
                                      colors.primary, 
                                      colors.primaryContainer,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  radius: 12, 
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
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  children: [
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(0)}%',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      lang.translate('saved').toUpperCase(),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // --- Legend Section ---
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Saved (Shows current progress)
                        _buildLegendItem(
                          label: lang.translate('saved'), 
                          value: goal.currentAmount, 
                          color: progressColor, 
                          theme: theme
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1, thickness: 0.5),
                        ),

                        // Remaining (Shows what's left)
                        _buildLegendItem(
                          label: lang.translate('remaining'), 
                          value: goal.targetAmount - goal.currentAmount, 
                          color: trackColor, 
                          theme: theme
                        ),
                        const SizedBox(height: 16),

                        // Add To Savings Button 
                        SizedBox(
                          width: double.infinity,
                          child: AddToSavingsButton(goal: goal),
                        ),
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