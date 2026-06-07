import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';

class SavingsGoalsTracker extends StatelessWidget {
  const SavingsGoalsTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final repo = context.read<SavingsRepository>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Savings Goals Progress",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),

        StreamBuilder<List<SavingsGoal>>(
          stream: repo.goalsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 0,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: SizedBox(
                  height: textScaler.scale(120),
                  child: const LoadingState(),
                ),
              );
            }

            final goals = snapshot.data ?? [];

            if (goals.isEmpty) {
              return Card(
                elevation: 0,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.track_changes_outlined, size: 32, color: colors.outline),
                        const SizedBox(height: 8),
                        Text(
                          "No active savings goals found.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Card(
              elevation: 0,
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 16.0, right: 16.0),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: goals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    
                    // Calculate explicit progress clamp
                    final progress = goal.targetAmount > 0 
                        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) 
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Goal Title & Percentage Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                goal.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "${(progress * 100).toStringAsFixed(0)}%",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Row 2: Sleek Progress Track Bar
                        // Wrap the indicator in a Stack to overlay the segment dividers
                        Stack(
                          children: [
                            // Smooth Gradient Progress Bar
                            LinearPercentIndicator(
                              lineHeight: 12.0,
                              animation: true,
                              percent: progress,
                              barRadius: const Radius.circular(6),
                              linearGradient: LinearGradient(colors: [colors.primary, colors.secondary]),
                              backgroundColor: colors.outlineVariant.withValues(alpha: 0.2),
                            ),
                            
                            // Segment Overlay (Creates the 'steps')
                            Positioned.fill(
                              child: Row(
                                children: List.generate(10, (index) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(color: colors.surface, width: 2),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Row 3: Numeric Breakdown metric labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Saved: ",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                CurrencyDisplay(
                                  amount: goal.currentAmount,
                                  isExpense: false, 
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            
                            Row(
                              children: [
                                Text(
                                  "Target: ",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.outline,
                                  ),
                                ),
                                CurrencyDisplay(
                                  amount: goal.targetAmount,
                                  compact: true,
                                  isExpense: false,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}