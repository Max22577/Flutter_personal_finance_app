import 'dart:ui';
import 'package:flutter/material.dart';
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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.4), 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.2), 
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _displayedDate = DateTime(_displayedDate.year - 1, _displayedDate.month)),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', lang.localeCode).format(_displayedDate),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _displayedDate = DateTime(_displayedDate.year + 1, _displayedDate.month)),
                  ),
                ],
              ),
              const Divider(),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final monthDate = DateTime(_displayedDate.year, index + 1);
                  final isSelected = monthDate.month == widget.initialDate.month && 
                                  monthDate.year == widget.initialDate.year;

                  return InkWell(
                    onTap: () => Navigator.pop(context, monthDate),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.surfaceContainerHigh.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('MMM', lang.localeCode).format(monthDate),
                        style: TextStyle(
                          color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}