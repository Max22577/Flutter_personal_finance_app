import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../view_models/budget_edit_view_model.dart';

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

  void _showSuccessToast() {
    final theme = Theme.of(context);
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.onPrimaryContainer, size: 20),
            const SizedBox(width: 12),
            Text('${widget.category.name} ${lang.translate('budget_updated')}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),),
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
      child: Consumer<BudgetEditViewModel>(
        builder: (context, vm, child) {
          final lang = context.read<LanguageProvider>();
          final currency = context.read<CurrencyProvider>().currency;
          
          return _buildAnimatedDialog(context, vm, lang, currency.symbol);
        },
      ),
    );
  }

  Widget _buildAnimatedDialog(BuildContext context, BudgetEditViewModel vm, LanguageProvider lang, String symbol) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final textScaler = MediaQuery.textScalerOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context); // Detects keyboard

    final icon = CategoryIconHelper.getIcon(widget.category);
    final iconColor = CategoryIconHelper.getColor(widget.category, colors);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Dialog(
        backgroundColor: colors.surface.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: SingleChildScrollView( 
          child: Padding(
            // Extra padding at bottom to clear the keyboard view inset
            padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + viewInsets.bottom * 0.1),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Header Section ---
                  Row(
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
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                            ),
                            Text(
                              lang.translate(widget.category.name), 
                              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // --- Input Section ---
                  // Use a Wrap here instead of fixed SizedBox for the input
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(symbol, style: theme.textTheme.headlineSmall?.copyWith(color: colors.primary)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: '0.00',
                      border: InputBorder.none, // "Glassy" input usually looks best without borders
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) => (value == null || double.tryParse(value) == null) 
                        ? lang.translate('enter_valid_positive_amount') 
                        : null,
                  ),
                  
                  const Divider(height: 32),

                  if (widget.currentBudget > 0) ...[
                    _buildPreviousBadge(colors, theme, lang, symbol),
                    const SizedBox(height: 24),
                  ],

                  // --- Action Buttons ---
                  // Wrap in a Row with Expanded for equal-height buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: vm.isSaving ? null : () => Navigator.pop(context),
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
                          onPressed: vm.isSaving ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              HapticFeedback.lightImpact();
                              final success = await vm.updateBudget(_amountController.text);
                              if (success && context.mounted) {
                                _showSuccessToast();
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: vm.isSaving 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(lang.translate('update_budget'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
  Widget _buildPreviousBadge(ColorScheme colors, ThemeData theme, LanguageProvider lang, String symbol) {
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
              '${lang.translate('previous')}: $symbol${widget.currentBudget.toStringAsFixed(0)}',
              style: theme.textTheme.labelMedium?.copyWith(color: colors.onSecondaryContainer),
            ),
          ),
        ],
      ),     
    );
  }
}