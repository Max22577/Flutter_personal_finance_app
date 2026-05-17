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
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.watch<LanguageProvider>();
    final financialColors = theme.extension<FinancialColors>() ??
        FinancialColors(income: Colors.green, expense: Colors.red);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool shouldStack = textScaler.scale(1.0) > 1.5;

        // Data for our buttons
        final types = [
          (id: 'Income', icon: Icons.arrow_upward_rounded, color: financialColors.income, label: lang.translate('income')),
          (id: 'Expense', icon: Icons.arrow_downward_rounded, color: financialColors.expense, label: lang.translate('expense')),
        ];

        final children = types.map((type) {
          final button = _TypeButton(
            label: type.label,
            icon: type.icon,
            color: type.color,
            isSelected: selectedType == type.id,
            onPressed: () => onTypeChanged(type.id),
          );

          // Handle layout spacing based on stack mode
          return shouldStack
              ? Padding(padding: const EdgeInsets.only(bottom: 8.0), child: button)
              : Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type.id == 'Income' ? 8.0 : 0,
                      left: type.id == 'Expense' ? 8.0 : 0,
                    ),
                    child: button,
                  ),
                );
        }).toList();

        return shouldStack ? Column(children: children) : Row(children: children);
      },
    );
  }
}


class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return OutlinedButton(
      onPressed: onPressed,
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
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}