import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../../view_models/budget_edit_view_model.dart';

class BudgetEditDialog extends StatefulWidget {
  final Category category;
  final double currentBudget;
  final String monthYear;
  final Future<void> Function(String categoryId, double amount, String monthYear) onSave;

  const BudgetEditDialog({
    super.key,
    required this.category,
    required this.currentBudget,
    required this.monthYear,
    required this.onSave,
  });

  @override
  State<BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends State<BudgetEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentBudget > 0 ? widget.currentBudget.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showSuccessToast(BuildContext context, String categoryName, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.onPrimaryContainer, size: 20),
            const SizedBox(width: 12),
            Text(
              '$categoryName $message',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BudgetEditViewModel(
        onSave: widget.onSave,
        categoryId: widget.category.id,
        monthYear: widget.monthYear,
      ),
      child: AnimatedScalingDialog(
        child: Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: SingleChildScrollView(
            child: Consumer<BudgetEditViewModel>(
              builder: (context, vm, _) {
                final lang = context.read<LanguageProvider>();
                final symbol = context.read<CurrencyProvider>().currency.symbol;
                final viewInsets = MediaQuery.viewInsetsOf(context);

                return Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + viewInsets.bottom * 0.1),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DialogHeader(category: widget.category),
                        const SizedBox(height: 24),
                        _BudgetAmountInputField(
                          controller: _amountController,
                          currencySymbol: symbol,
                        ),
                        const Divider(height: 32),
                        if (widget.currentBudget > 0) ...[
                          _PreviousBudgetBadge(
                            currentBudget: widget.currentBudget,
                            currencySymbol: symbol,
                          ),
                          const SizedBox(height: 24),
                        ],
                        _DialogActionButtons(
                          isSaving: vm.isSaving,
                          onCancel: () => Navigator.pop(context),
                          onConfirm: () async {
                            if (_formKey.currentState!.validate()) {
                              HapticFeedback.lightImpact();
                              final success = await vm.updateBudget(_amountController.text);
                              if (success && context.mounted) {
                                _showSuccessToast(
                                  context,
                                  lang.translate(widget.category.name),
                                  lang.translate('budget_updated'),
                                );
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


class _DialogHeader extends StatelessWidget {
  final Category category;

  const _DialogHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final lang = context.watch<LanguageProvider>();

    final icon = CategoryIconHelper.getIcon(category);
    final iconColor = CategoryIconHelper.getColor(category, colors);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: textScaler.scale(24)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.translate('edit_budget'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                lang.translate(category.name),
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetAmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;

  const _BudgetAmountInputField({
    required this.controller,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return TextFormField(
      controller: controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: colors.onSurface,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            currencySymbol,
            style: theme.textTheme.titleMedium?.copyWith(color: colors.primary),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: '0.00',
        contentPadding: EdgeInsets.zero,
      ),
      validator: (value) => (value == null || double.tryParse(value) == null)
          ? lang.translate('enter_valid_positive_amount')
          : null,
    );
  }
}

class _PreviousBudgetBadge extends StatelessWidget {
  final double currentBudget;
  final String currencySymbol;

  const _PreviousBudgetBadge({
    required this.currentBudget,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ShapeDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.5),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 14, color: colors.onSecondaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${lang.translate('previous')}: $currencySymbol${currentBudget.toStringAsFixed(0)}',
              style: theme.textTheme.labelMedium?.copyWith(color: colors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogActionButtons extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DialogActionButtons({
    required this.isSaving,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: isSaving ? null : onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(lang.translate('cancel')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isSaving ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    lang.translate('update_budget'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

// REUSABLE WIDGETS
class AnimatedScalingDialog extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedScalingDialog({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutBack,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}