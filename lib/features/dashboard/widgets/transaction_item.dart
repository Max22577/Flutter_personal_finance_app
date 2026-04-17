import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              minHeight: 72, // Ensure minimum height
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon - Fixed size
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: iconColor,
                      size: 20,
                    ),
                  ),

                  // Title and details - Takes remaining space
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          transaction.title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Details row
                        SizedBox(
                          height: 20, // Fixed height for details
                          child: _buildDetails(context, lang),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Amount - Fixed width
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 80,
                      maxWidth: 120,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Amount
                        CurrencyDisplay(
                          amount: transaction.amount,
                          isExpense: isIncome ? false : true,
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
                                size: 14,
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                              onPressed: onEdit,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, LanguageProvider lang) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    final details = <Widget>[];
    
    // Category
    if (showCategory && categoryName!.isNotEmpty) {
      details.add(
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            lang.translate(categoryName?.toUpperCase() ?? ''),
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }
    
    // Date and Time
    if (showDate || showTime) {
      final dateParts = <String>[];
      if (showDate) {
        dateParts.add(DateFormat('MMM d').format(transaction.date));
      }
      if (showTime) {
        dateParts.add(DateFormat('h:mm a').format(transaction.date));
      }
      
      if (dateParts.isNotEmpty) {
        if (details.isNotEmpty) {
          details.add(const SizedBox(width: 8));
        }
        
        details.add(
          Flexible(
            child: Text(
              dateParts.join(' • '),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: details,
    );
  }
}