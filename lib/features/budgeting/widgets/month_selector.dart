import 'package:flutter/material.dart';
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
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Subtle shadow or "Glass" effect
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: colors.surface, 
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded, 
                    color: colors.primary, 
                    size: 22
                  ),
                ),
                const SizedBox(width: 16),
                
                // Date Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            lang.translate('budget_period'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              
                            ),
                          ),
                          if (_isCurrentMonth()) ...[
                            const SizedBox(width: 8),
                            _buildCurrentBadge(colors, lang),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMMM yyyy', lang.localeCode).format(selectedDate),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive indicator
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBadge(ColorScheme colors, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        lang.translate('this_month'),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}