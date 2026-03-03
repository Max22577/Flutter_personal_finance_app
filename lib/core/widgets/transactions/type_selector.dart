import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';
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
    // Get theme properties
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.watch<LanguageProvider>();
    
    final isIncome = selectedType == 'Income';
    final isExpense = selectedType == 'Expense';

    return Row(
      children: [
        // Income Button
        Expanded(
          child: OutlinedButton(
            onPressed: () => onTypeChanged('Income'),
            style: OutlinedButton.styleFrom(
              backgroundColor: isIncome 
                  ? financialColors.income.withValues(alpha: 0.1) // Selected state
                  : colors.surfaceContainerHigh.withValues(alpha: 0.5), // Unselected state
              foregroundColor: isIncome 
                  ? financialColors.income 
                  : colors.onSurfaceVariant,
              side: BorderSide(
                color: isIncome 
                    ? financialColors.income // Selected border
                    : colors.outline.withValues(alpha: 0.3), // Unselected border
                width: isIncome ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: isIncome ? financialColors.income : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  lang.translate('income'),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: isIncome ? FontWeight.bold : FontWeight.normal,
                    color: isIncome ? financialColors.income : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Expense Button
        Expanded(
          child: OutlinedButton(
            onPressed: () => onTypeChanged('Expense'),
            style: OutlinedButton.styleFrom(
              backgroundColor: isExpense 
                  ? financialColors.expense.withValues(alpha: 0.1) // Selected state
                  : colors.surfaceContainerHigh.withValues(alpha: 0.5), // Unselected state
              foregroundColor: isExpense 
                  ? financialColors.expense 
                  : colors.onSurfaceVariant,
              side: BorderSide(
                color: isExpense 
                    ? financialColors.expense // Selected border
                    : colors.outline.withValues(alpha: 0.3), // Unselected border
                width: isExpense ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 18,
                  color: isExpense ? financialColors.expense : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  lang.translate('expense'),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: isExpense ? FontWeight.bold : FontWeight.normal,
                    color: isExpense ? financialColors.expense : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}