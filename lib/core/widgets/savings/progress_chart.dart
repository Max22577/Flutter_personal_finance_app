import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/savings/add_to_savings_button.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:provider/provider.dart';
import '../../../models/savings.dart';

class ProgressChartWidget extends StatelessWidget {
  final SavingsGoal goal;
  
  const ProgressChartWidget({required this.goal, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currency = context.watch<CurrencyProvider>().currency;
    final lang = context.watch<LanguageProvider>();
    
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
                      height: 160,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 55, // Increased for a thin ring look
                              startDegreeOffset: -90,
                              sections: [
                                PieChartSectionData(
                                  value: goal.currentAmount,
                                  color: colors.primary,
                                  radius: 18, // Thicker ring
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: goal.targetAmount - goal.currentAmount,
                                  color: colors.primaryContainer.withValues(alpha: 0.4),
                                  radius: 14, // Slightly thinner background ring
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
                                  '${currency.symbol}${goal.currentAmount.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: colors.primary,
                                  ),
                                ),
                                Text(
                                  lang.translate('saved'),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold,
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
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: colors.outlineVariant, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              goal.name,
                              style: theme.textTheme.labelLarge?.copyWith(
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildLegend(
                          label: lang.translate('target'), 
                          value: goal.targetAmount, 
                          color: colors.outlineVariant, 
                          theme: theme
                        ),
                        const SizedBox(height: 16),
                        _buildLegend(
                          label: lang.translate('remaining'), 
                          value: goal.targetAmount - goal.currentAmount, 
                          color: colors.primaryContainer, 
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
        const SizedBox(width: 12),
        Text(
          lang.translate('goal_progress'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegend({
    required String label, 
    required double value, 
    required Color color, 
    required ThemeData theme
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.5,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Replace with your CurrencyDisplay widget
        CurrencyDisplay(
          amount: value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}