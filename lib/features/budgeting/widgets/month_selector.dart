import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:provider/provider.dart';

class MonthSelectorCard extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const MonthSelectorCard({
    super.key,
    required this.selectedDate,
    required this.onTap,
  });

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return now.month == selectedDate.month && now.year == selectedDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();
    final textScaler = MediaQuery.textScalerOf(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      // Using Card's built-in clip behavior for cleaner corners
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Section (Fixed size but scales with text)
              _buildLeadingIcon(colors, textScaler),
              
              const SizedBox(width: 16),
              
              // Text Section (Fluid)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Wrap allows the badge to move if "BUDGET PERIOD" is long
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          lang.translate('budget_period').toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (_isCurrentMonth()) _buildCurrentBadge(colors, lang),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM yyyy', lang.localeCode).format(selectedDate),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8,
                        // Prevents text from being massive on accessibility settings
                        fontSize: textScaler.scale(20).clamp(18.0, 24.0),
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing Indicator
              Icon(
                Icons.unfold_more_rounded, 
                color: colors.primary.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ColorScheme colors, TextScaler textScaler) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.calendar_month_rounded, 
        color: colors.primary, 
        size: textScaler.scale(24).clamp(20, 30),
      ),
    );
  }

  Widget _buildCurrentBadge(ColorScheme colors, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: colors.primary,
        shape: const StadiumBorder(), // Pill shape looks more modern
      ),
      child: Text(
        lang.translate('this_month'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}