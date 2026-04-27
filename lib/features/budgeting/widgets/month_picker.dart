import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:provider/provider.dart';

class MonthPickerSheet extends StatefulWidget {
  final DateTime initialDate;

  const MonthPickerSheet({super.key, required this.initialDate});

  @override
  State<MonthPickerSheet> createState() => _MonthPickerSheetState();

  static Future<DateTime?> show(BuildContext context, DateTime initialDate) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent, 
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MonthPickerSheet(initialDate: initialDate),
    );
  }
}

class _MonthPickerSheetState extends State<MonthPickerSheet> {
  late DateTime _displayedDate;

  @override
  void initState() {
    super.initState();
    _displayedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();
    final textScaler = MediaQuery.textScalerOf(context);

    return Container(
      padding: const EdgeInsets.only(top: 12), 
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => setState(() => 
                      _displayedDate = DateTime(_displayedDate.year - 1, _displayedDate.month)),
                ),
                Column(
                  children: [
                    Text(
                      _displayedDate.year.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Quick jump back to "Current Month"
                    GestureDetector(
                      onTap: () => setState(() => _displayedDate = DateTime.now()),
                      child: Text(
                        lang.translate('go_to_today').toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onPressed: () => setState(() => 
                      _displayedDate = DateTime(_displayedDate.year + 1, _displayedDate.month)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Using a slightly more square ratio for better touch targets
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: textScaler.scale(1.3), 
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthDate = DateTime(_displayedDate.year, index + 1);
                final isSelected = monthDate.month == widget.initialDate.month && 
                                   monthDate.year == widget.initialDate.year;
                final isCurrentMonth = monthDate.month == DateTime.now().month && 
                                       monthDate.year == DateTime.now().year;

                return _buildMonthButton(
                  context, 
                  monthDate: monthDate, 
                  isSelected: isSelected, 
                  isCurrentMonth: isCurrentMonth,
                  lang: lang,
                );
              },
            ),
          ),
        ],
      ),
    );  
  }

  Widget _buildMonthButton(
    BuildContext context, {
    required DateTime monthDate,
    required bool isSelected,
    required bool isCurrentMonth,
    required LanguageProvider lang,
  }) {
    final colors = Theme.of(context).colorScheme;
    
    return Material(
      color: isSelected 
          ? colors.primary 
          : isCurrentMonth 
              ? colors.primaryContainer.withValues(alpha: 0.4) 
              : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context, monthDate);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: isCurrentMonth && !isSelected
                ? Border.all(color: colors.primary.withValues(alpha: 0.5))
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            DateFormat('MMMM', lang.localeCode).format(monthDate),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? colors.onPrimary : colors.onSurface,
              fontWeight: isSelected || isCurrentMonth ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}