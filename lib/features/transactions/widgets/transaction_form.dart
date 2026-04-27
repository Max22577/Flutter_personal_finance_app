import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/core/utils/ui_helpers.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/features/transactions/widgets/category_dropdown.dart';
import 'package:personal_fin/features/transactions/widgets/type_selector.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart' show Transaction;
import 'package:provider/provider.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? transactionToEdit;
  const TransactionForm({this.transactionToEdit, super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  
  late String _selectedType;
  Category? _selectedCategory; 
  late DateTime _selectedDate;
  String? _currencySymbol; 

  @override
  void initState() {
    super.initState();
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    _currencySymbol = currencyProvider.currency.symbol;
    
    final tx = widget.transactionToEdit;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(text: tx != null ? tx.amount.toStringAsFixed(2) : '');
    _selectedType = tx?.type ?? 'Expense';
    _selectedDate = tx?.date ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<TransactionViewModel>(context, listen: false);
      if (vm.categories.isNotEmpty) {
        setState(() {
          _selectedCategory = widget.transactionToEdit != null 
              ? vm.categories.firstWhere((c) => c.id == widget.transactionToEdit!.categoryId)
              : vm.categories.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount(String input) {
    if (input.isEmpty) return null;
    
    try {
      String cleaned = input.replaceAll(_currencySymbol ?? '', '');
      cleaned = cleaned.replaceAll(',', '').trim();
      
      return double.tryParse(cleaned);
    } catch (e) {
      debugPrint('Error parsing amount: $e');
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleSubmit(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    final vm = context.read<TransactionViewModel>();
    
    try {
      final success = await vm.saveTransaction(
        title: _titleController.text,
        amount: double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')),
        type: _selectedType,
        categoryId: _selectedCategory!.id,
        date: _selectedDate,
        existingTransaction: widget.transactionToEdit,
      );

      if (success && mounted) { 
        Navigator.pop(context);
        showFeedback(
          context, 
          lang.translate('saved'), 
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        showFeedback(
          context, 
          '${lang.translate('error')}: ${e.toString()}', 
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TransactionViewModel>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();
    final cf = context.watch<CurrencyProvider>().formatter;
    final financialColors = theme.extension<FinancialColors>() ?? FinancialColors(income: Colors.green, expense: Colors.red);
    final isIncome = _selectedType == 'Income';
    final typeColor = isIncome ? financialColors.income : financialColors.expense;
    final textScaler = MediaQuery.textScalerOf(context);
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // The "Frosted" intensity
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.7), 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.2), 
              width: 1.5,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    widget.transactionToEdit != null ? lang.translate('edit_transaction') : lang.translate('new_transaction'),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Type Selector
                  TypeSelector(
                    selectedType: _selectedType,
                    onTypeChanged: (newType) {
                      setState(() {
                        _selectedType = newType;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Amount Field with Currency Symbol ---
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: lang.translate('amount'),
                      prefixIcon: Icon(Icons.money, color: typeColor),
                      prefixText: _currencySymbol != null ? '$_currencySymbol ' : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
                      labelStyle: TextStyle(color: typeColor),
                      hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
                    ),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang.translate('err_amount_empty');
                      }
                      
                      final amount = _parseAmount(value);
                      if (amount == null) {
                        return lang.translate('err_amount_invalid');
                      }
                      if (amount <= 0) {
                        return lang.translate('err_amount_zero');
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Optional: Format as user types
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Title / Description ---
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: lang.translate('title_desc'),
                      hintText: lang.translate('title_hint'),
                      prefixIcon: Icon(Icons.description, color: colors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
                      labelStyle: TextStyle(color: colors.primary),
                      hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
                    ),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                    validator: (value) => value == null || value.isEmpty ? lang.translate('err_title_empty') : null,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 20),
                  
                  // 2. REUSED WIDGET: Category Dropdown
                  CategoryDropdown(
                    selectedCategory: _selectedCategory,
                    categories: vm.categories,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Date Picker ---
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: lang.translate('date'),
                        prefixIcon: Icon(Icons.calendar_today, color: colors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
                        labelStyle: TextStyle(color: colors.primary),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded( // Allows text to wrap or shrink if font is huge
                            child: Text(
                              DateFormat('MMMM d, yyyy', lang.localeCode).format(_selectedDate),
                              style: textTheme.bodyLarge,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: colors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Save Button ---
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: textScaler.scale(48)),
                    child: ElevatedButton(
                      onPressed: vm.isSaving ? null : () => _handleSubmit(lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isIncome ? financialColors.income : financialColors.expense,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: colors.shadow,
                      ),
                      child: vm.isSaving
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              widget.transactionToEdit != null ? lang.translate('update_transaction') : lang.translate('save_transaction'),
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 50),
                  
                  // preview 
                  if (_amountController.text.isNotEmpty)
                    _buildPreview(cf, lang, textTheme, typeColor, isIncome),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(CurrencyFormatter cf, LanguageProvider lang, TextTheme textTheme, Color typeColor, bool isIncome) {
    return FutureBuilder<String>(
      future: () async {
        final amount = _parseAmount(_amountController.text);
        if (amount == null || amount <= 0) return '';
        return cf.formatNumber(amount, lang.localeCode);
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: typeColor.withValues(alpha: 0.3)),
            ),
            child: Wrap( 
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward, color: typeColor, size: 20),
                Text(
                  '${lang.translate('preview')}: ${isIncome ? '+' : '-'}${snapshot.data}',
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: typeColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}