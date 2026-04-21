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
          final lang = context.watch<LanguageProvider>();
          final currency = context.watch<CurrencyProvider>().currency;
          
          return _buildAnimatedDialog(context, vm, lang, currency.symbol);
        },
      ),
    );
  }

  Widget _buildAnimatedDialog(BuildContext context, BudgetEditViewModel vm, LanguageProvider lang, String symbol) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = CategoryIconHelper.getIcon(widget.category);
    final iconColor = CategoryIconHelper.getColor(widget.category, colors);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(25.0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // The "Frosted" intensity
            child: Container(
              decoration: BoxDecoration(
                // Tint the glass: White for light mode, Black/Grey for dark mode
                color: colors.surface.withValues(alpha: 0.4), 
                borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.2), 
                  width: 1.5,
                ),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(15),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Header Section ---
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: iconColor.withValues(alpha: 0.15) ,
                            child: Icon(icon, color: iconColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lang.translate('edit_budget'), style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, letterSpacing: -1)),
                                Text(lang.translate(widget.category.name), style: theme.textTheme.titleMedium?.copyWith(color: colors.outline, letterSpacing: -1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // --- Input Section ---
                      SizedBox(
                        width: 250, 
                        child: TextFormField(
                          controller: _amountController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.start,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end, 
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 20), 
                                  child: Text(
                                    symbol.isNotEmpty ? symbol : " ",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: colors.outline.withValues(alpha: 0.5), 
                                      fontSize: 20,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 2),
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: colors.primary, width: 2),
                            ),
                          ),
                          validator: (value) => (value == null || double.tryParse(value) == null) ? lang.translate('enter_valid_positive_amount') : null,
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      if (widget.currentBudget > 0) _buildPreviousBadge(colors, theme, lang, symbol),
                      const SizedBox(height: 32),

                      // --- Action Buttons ---
                      Row(
                        children: [
                          Expanded(
                            flex: 1, // Proportional width
                            child: OutlinedButton(
                              onPressed: vm.isSaving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16), // Matched height
                                side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
                                backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.3), // Subtle glass feel
                                foregroundColor: colors.onSurfaceVariant,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                lang.translate('cancel'),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: vm.isSaving ? null : () async {
                                if (_formKey.currentState!.validate()) {
                                  HapticFeedback.mediumImpact();
                                  final success = await vm.updateBudget(_amountController.text);
                                  
                                  if (success && context.mounted) {                                  
                                    _showSuccessToast();
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primaryContainer,
                                foregroundColor: colors.onPrimaryContainer,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: vm.isSaving 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                :  Text(lang.translate('update_budget'), style: TextStyle(fontWeight: FontWeight.bold)),
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