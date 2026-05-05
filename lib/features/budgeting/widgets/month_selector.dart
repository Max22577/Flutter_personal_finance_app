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

  bool get _isCurrentMonth {
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
              // Scalable Icon Section
              _LeadingCalendarIcon(colors: colors, textScaler: textScaler),
              
              const SizedBox(width: 16),
              
              // Fluid Content Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PeriodHeader(
                      isCurrent: _isCurrentMonth,
                      label: lang.translate('budget_period'),
                      badgeLabel: lang.translate('this_month'),
                    ),
                    const SizedBox(height: 4),
                    _FormattedDateText(
                      date: selectedDate,
                      locale: lang.localeCode,
                      textScaler: textScaler,
                    ),
                  ],
                ),
              ),

              // Trailing Interaction Hint
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
}

class _LeadingCalendarIcon extends StatelessWidget {
  final ColorScheme colors;
  final TextScaler textScaler;

  const _LeadingCalendarIcon({required this.colors, required this.textScaler});

  @override
  Widget build(BuildContext context) {
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
}

class _PeriodHeader extends StatelessWidget {
  final bool isCurrent;
  final String label;
  final String badgeLabel;

  const _PeriodHeader({
    required this.isCurrent,
    required this.label,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.0,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (isCurrent) 
          StatusBadge(label: badgeLabel, isPrimary: true),
      ],
    );
  }
}

class _FormattedDateText extends StatelessWidget {
  final DateTime date;
  final String locale;
  final TextScaler textScaler;

  const _FormattedDateText({
    required this.date,
    required this.locale,
    required this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('MMMM yyyy', locale).format(date),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
            fontSize: textScaler.scale(20).clamp(18.0, 24.0),
          ),
    );
  }
}

// REUSABLE WIDGETS

class StatusBadge extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final Color? customColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.isPrimary = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bgColor = customColor ?? (isPrimary ? colors.primary : colors.secondaryContainer);
    final textColor = isPrimary ? colors.onPrimary : colors.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: bgColor,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}