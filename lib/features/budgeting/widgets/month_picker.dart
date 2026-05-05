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

  void _updateYear(int delta) {
    setState(() {
      _displayedDate = DateTime(_displayedDate.year + delta, _displayedDate.month);
    });
  }

  void _goToToday() {
    setState(() => _displayedDate = DateTime.now());
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bottom Sheet Drag Handle
          const _SheetHandle(),

          // Year Selector Header
          _YearSelector(
            displayedYear: _displayedDate.year,
            onPrev: () => _updateYear(-1),
            onNext: () => _updateYear(1),
            onToday: _goToToday,
            todayLabel: lang.translate('go_to_today'),
          ),

          // Month Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: _MonthGrid(
              displayedYear: _displayedDate.year,
              initialDate: widget.initialDate,
              locale: lang.localeCode,
            ),
          ),
        ],
      ),
    );
  }
}


class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int displayedYear;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final String todayLabel;

  const _YearSelector({
    required this.displayedYear,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.todayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: onPrev,
          ),
          Column(
            children: [
              Text(
                displayedYear.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: onToday,
                child: Text(
                  todayLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final int displayedYear;
  final DateTime initialDate;
  final String locale;

  const _MonthGrid({
    required this.displayedYear,
    required this.initialDate,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: textScaler.scale(1.3),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final monthDate = DateTime(displayedYear, index + 1);
        final isSelected = monthDate.month == initialDate.month && 
                           monthDate.year == initialDate.year;
        final isToday = monthDate.month == now.month && 
                        monthDate.year == now.year;

        return SelectionTile(
          label: DateFormat('MMMM', locale).format(monthDate),
          isSelected: isSelected,
          isHighlight: isToday,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context, monthDate);
          },
        );
      },
    );
  }
}

class SelectionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isHighlight;
  final VoidCallback onTap;

  const SelectionTile({
    super.key,
    required this.label,
    required this.isSelected,
    this.isHighlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final bgColor = isSelected
        ? colors.primary
        : isHighlight
            ? colors.primaryContainer.withValues(alpha: 0.4)
            : colors.surfaceContainerLow;

    final textColor = isSelected 
        ? colors.onPrimary 
        : colors.onSurface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isHighlight && !isSelected
                ? Border.all(color: colors.primary.withValues(alpha: 0.5))
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: isSelected || isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}