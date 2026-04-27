import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:provider/provider.dart'; 

class TypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const TypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>() ??
        FinancialColors(income: Colors.green, expense: Colors.red);
    final lang = context.watch<LanguageProvider>();
    final textScaler = MediaQuery.textScalerOf(context);

    // We use a LayoutBuilder to decide if we should stack the buttons
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the font is so large that horizontal space is tight, we stack them
        final bool shouldStack = textScaler.scale(1.0) > 1.5;

        return shouldStack 
          ? Column(children: _buildButtons(context, lang, financialColors, colors, textTheme, true))
          : Row(children: _buildButtons(context, lang, financialColors, colors, textTheme, false));
      },
    );
  }

  List<Widget> _buildButtons(
    BuildContext context,
    LanguageProvider lang,
    FinancialColors financialColors,
    ColorScheme colors,
    TextTheme textTheme,
    bool isStacked,
  ) {
    final types = [
      ('Income', Icons.arrow_upward_rounded, financialColors.income, lang.translate('income')),
      ('Expense', Icons.arrow_downward_rounded, financialColors.expense, lang.translate('expense')),
    ];

    return types.map((type) {
      final isSelected = selectedType == type.$1;
      final color = type.$3;
      final label = type.$4;
      final icon = type.$2;

      Widget button = OutlinedButton(
        onPressed: () => onTypeChanged(type.$1),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? color.withValues(alpha: 0.1)
              : colors.surfaceContainerHigh.withValues(alpha: 0.5),
          foregroundColor: isSelected ? color : colors.onSurfaceVariant,
          side: BorderSide(
            color: isSelected ? color : colors.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Flexible( // Prevents text from pushing icon out of the button
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

      // Add spacing/expansion logic based on layout mode
      if (isStacked) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SizedBox(width: double.infinity, child: button),
        );
      } else {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type.$1 == 'Income' ? 8.0 : 0,
              left: type.$1 == 'Expense' ? 8.0 : 0,
            ),
            child: button,
          ),
        );
      }
    }).toList();
  }
}