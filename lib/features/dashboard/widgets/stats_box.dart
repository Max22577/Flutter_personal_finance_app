import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:provider/provider.dart';

class StatBox extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData? icon;
  final bool showSign;
  final bool compact;

  const StatBox({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.icon,
    this.showSign = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final cf = context.watch<CurrencyProvider>().formatter;
    final lang = context.watch<LanguageProvider>();

    final textScaler = MediaQuery.textScalerOf(context);

    final sign = showSign && value != 0 
        ? (value > 0 ? '+' : '-') 
        : '';

    final formattedValue = compact 
        ? cf.formatCompact(value.abs(), lang.localeCode) 
        : cf.formatDisplay(value.abs(), lang.localeCode);
    
    return Container(
      padding: EdgeInsets.all(textScaler.scale(compact ? 8 : 12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: textScaler.scale(compact ? 14 : 16),
                  color: color,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: (compact ? textTheme.labelSmall : textTheme.bodySmall)?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            '$sign$formattedValue',
            style: (compact ? textTheme.bodySmall : textTheme.titleSmall)?.copyWith(
              fontWeight: FontWeight.bold, 
              color: theme.colorScheme.onSurface,
            ),
          ),         
        ],
      ),
    );
  }
}