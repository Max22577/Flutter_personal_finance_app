import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/currency_display.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compactAmount;

  const TransactionTile({
    required this.transaction,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.compactAmount = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final financialColors = theme.extension<FinancialColors>() ?? 
        FinancialColors(income: Colors.green, expense: Colors.red);
    final lang = context.watch<LanguageProvider>();

    final isIncome = transaction.type == 'Income';
    final statusColor = isIncome ? financialColors.income : financialColors.expense;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icon + Title + Amount
                _TileHeader(
                  transaction: transaction,
                  statusColor: statusColor,
                  isIncome: isIncome,
                ),
                const SizedBox(height: 12),

                // Details: Category + Time
                _TileDetails(
                  transaction: transaction,
                  categoryName: categoryName,
                  lang: lang,
                ),
                const Divider(height: 24),

                // Actions: Edit + Delete
                _TileActions(
                  onEdit: onEdit,
                  onDelete: onDelete,
                  lang: lang,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _TileHeader extends StatelessWidget {
  final Transaction transaction;
  final Color statusColor;
  final bool isIncome;

  const _TileHeader({
    required this.transaction,
    required this.statusColor,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TransactionIcon(statusColor: statusColor, isIncome: isIncome),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 8,
            runSpacing: 4,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: textScaler.scale(200)),
                child: Text(
                  transaction.title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CurrencyDisplay(
                baseAmount: transaction.amount,
                isExpense: !isIncome,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionIcon extends StatelessWidget {
  final Color statusColor;
  final bool isIncome;

  const _TransactionIcon({required this.statusColor, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return Container(
      width: textScaler.scale(36),
      height: textScaler.scale(36),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        color: statusColor,
        size: textScaler.scale(18),
      ),
    );
  }
}

class _TileDetails extends StatelessWidget {
  final Transaction transaction;
  final String categoryName;
  final LanguageProvider lang;

  const _TileDetails({
    required this.transaction,
    required this.categoryName,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (categoryName.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              lang.translate(categoryName),
              style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        Text(
          DateFormat('h:mm a').format(transaction.date),
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _TileActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final LanguageProvider lang;

  const _TileActions({
    required this.onEdit,
    required this.onDelete,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _ActionButton(
          icon: Icons.edit_outlined,
          label: lang.translate('edit'),
          color: colors.primary,
          onPressed: onEdit,
        ),
        _ActionButton(
          icon: Icons.delete_outline,
          label: lang.translate('delete'),
          color: colors.error,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: textScaler.scale(16), color: color),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size(0, textScaler.scale(32)),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
