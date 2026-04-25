import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/currency_display.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String? categoryName;
  final bool showDate;
  final bool showCategory;
  final bool showTime;
  final bool showEditButton;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool compactAmount;
  final bool alwaysShowSign;

  const TransactionItem({
    required this.transaction,
    this.categoryName,
    this.showDate = false,
    this.showCategory = false,
    this.showTime = false,
    this.showEditButton = false,
    this.compactAmount = false,
    this.alwaysShowSign = false,
    this.onTap,
    this.onEdit,
    super.key,
  });

  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>() ?? FinancialColors(income: Colors.green, expense: Colors.red);
    final lang = context.watch<LanguageProvider>();

    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeFont = textScaler.scale(1) > 1.3;
    
    final isIncome = transaction.type == 'Income';
    final iconColor = isIncome ? financialColors.income : financialColors.expense;
    final bgColor = isIncome ? 
        financialColors.income.withValues(alpha: 0.1) : 
        financialColors.expense.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(
              minHeight: textScaler.scale(72), // Ensure minimum height
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.2),
              ),
              boxShadow: theme.brightness == Brightness.dark ? null : [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(textScaler.scale(12)),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Icon + Title Group
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon - Fixed size
                      _buildIcon(bgColor, iconColor, isIncome, textScaler),
                      const SizedBox(width: 12),

                      // Title and details - Takes remaining space
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              transaction.title,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            
                            // Details row
                            const SizedBox(height: 4),
                            _buildDetails(context, lang, textScaler),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Amount - Fixed width
                      Padding(
                        padding: EdgeInsets.only(top: isLargeFont ? 8 : 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: isLargeFont ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Amount
                                CurrencyDisplay(
                                  amount: transaction.amount,
                                  isExpense: !isIncome ,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  compact: compactAmount,
                                  showSign: alwaysShowSign,
                                  positiveColor: financialColors.income,
                                  negativeColor: financialColors.expense,
                                ),
                                
                                // Edit button below amount
                                if (showEditButton)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined, 
                                        size: textScaler.scale(16),
                                        color: colors.onSurface.withValues(alpha: 0.6),
                                      ),
                                      onPressed: onEdit,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color bgColor, Color iconColor, bool isIncome, TextScaler textScaler) {
    final size = textScaler.scale(40);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(
        isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        color: iconColor,
        size: textScaler.scale(20),
      ),
    );
  }

  

  Widget _buildDetails(BuildContext context, LanguageProvider lang, TextScaler textScaler) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // We use a Wrap here too so Category and Date can stack if they get too wide
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showCategory && categoryName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              categoryName!,
              style: theme.textTheme.labelSmall,
            ),
          ),
        if (showDate || showTime)
          Text(
            _formatDate(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  String _formatDate() {
    // Simplified for example
    return "${transaction.date.day}/${transaction.date.month}";
  }
}