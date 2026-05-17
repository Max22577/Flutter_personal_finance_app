import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/features/transactions/views/widgets/transaction_form/category_dropdown.dart';
import 'package:personal_fin/features/transactions/views/widgets/transaction_form/type_selector.dart';
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
    final currencyProvider = context.read<CurrencyProvider>();
    final code = currencyProvider.currency.code;
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    try {
      final success = await vm.saveTransaction(
        title: _titleController.text,
        amount: double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')),
        currency: code,
        type: _selectedType,
        categoryId: _selectedCategory!.id,
        date: _selectedDate,
        existingTransaction: widget.transactionToEdit,
      );

      if (success && mounted) { 
        Navigator.pop(context);
        AppFeedback.show(
          messenger, 
          lang.translate('saved'),
          colors: colors,
          textTheme: textTheme, 
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          messenger, 
          '${lang.translate('error')}: ${e.toString()}',
          colors: colors,
          textTheme: textTheme, 
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
    
    final financialColors = theme.extension<FinancialColors>() ?? 
        FinancialColors(income: Colors.green, expense: Colors.red);
    final isIncome = _selectedType == 'Income';
    final typeColor = isIncome ? financialColors.income : financialColors.expense;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
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
                    widget.transactionToEdit != null 
                        ? lang.translate('edit_transaction') 
                        : lang.translate('new_transaction'),
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

                  // Amount Field
                  _AmountField(
                    controller: _amountController,
                    currencySymbol: _currencySymbol,
                    typeColor: typeColor,
                    colors: colors,
                    textTheme: textTheme,
                    lang: lang,
                    parseAmount: _parseAmount,
                    onChanged: (_) => setState(() {}), // Force rebuild to update the live preview
                  ),
                  const SizedBox(height: 20),

                  // Title Field
                  _TitleField(
                    controller: _titleController,
                    colors: colors,
                    textTheme: textTheme,
                    lang: lang,
                  ),
                  const SizedBox(height: 20),

                  // Category Selector
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

                  // Date Picker
                  CustomDatePickerField(
                    selectedDate: _selectedDate,
                    localeCode: lang.localeCode,
                    labelText: lang.translate('date'),
                    colors: colors,
                    textTheme: textTheme,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  _SaveButton(
                    isSaving: vm.isSaving,
                    buttonColor: typeColor,
                    buttonText: widget.transactionToEdit != null 
                        ? lang.translate('update_transaction') 
                        : lang.translate('save_transaction'),
                    textTheme: textTheme,
                    colors: colors,
                    onPressed: () => _handleSubmit(lang),
                  ),
                  const SizedBox(height: 50),
                  
                  // Live Preview
                  _TransactionPreview(
                    amountText: _amountController.text,
                    cf: cf,
                    lang: lang,
                    textTheme: textTheme,
                    typeColor: typeColor,
                    isIncome: isIncome,
                    parseAmount: _parseAmount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final String localeCode;
  final String labelText;
  final ColorScheme colors;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const CustomDatePickerField({
    super.key,
    required this.selectedDate,
    required this.localeCode,
    required this.labelText,
    required this.colors,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
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
            Expanded(
              child: Text(
                DateFormat('MMMM d, yyyy', localeCode).format(selectedDate),
                style: textTheme.bodyLarge,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String? currencySymbol;
  final Color typeColor;
  final ColorScheme colors;
  final TextTheme textTheme;
  final LanguageProvider lang;
  final double? Function(String) parseAmount;
  final ValueChanged<String> onChanged;

  const _AmountField({
    required this.controller,
    required this.currencySymbol,
    required this.typeColor,
    required this.colors,
    required this.textTheme,
    required this.lang,
    required this.parseAmount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: lang.translate('amount'),
        prefixIcon: Icon(Icons.money, color: typeColor),
        prefixText: currencySymbol != null ? '$currencySymbol ' : null,
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
        final amount = parseAmount(value);
        if (amount == null) {
          return lang.translate('err_amount_invalid');
        }
        if (amount <= 0) {
          return lang.translate('err_amount_zero');
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}

class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colors;
  final TextTheme textTheme;
  final LanguageProvider lang;

  const _TitleField({
    required this.controller,
    required this.colors,
    required this.textTheme,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final Color buttonColor;
  final String buttonText;
  final TextTheme textTheme;
  final ColorScheme colors;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isSaving,
    required this.buttonColor,
    required this.buttonText,
    required this.textTheme,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: textScaler.scale(48)),
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: colors.shadow,
        ),
        child: isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                buttonText,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _TransactionPreview extends StatelessWidget {
  final String amountText;
  final CurrencyFormatter cf;
  final LanguageProvider lang;
  final TextTheme textTheme;
  final Color typeColor;
  final bool isIncome;
  final double? Function(String) parseAmount;

  const _TransactionPreview({
    required this.amountText,
    required this.cf,
    required this.lang,
    required this.textTheme,
    required this.typeColor,
    required this.isIncome,
    required this.parseAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (amountText.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<String>(
      future: () async {
        final amount = parseAmount(amountText);
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