import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/core/widgets/transactions/category_dropdown.dart';
import 'package:provider/provider.dart';
import '../../../models/transaction.dart';
import '../theme/app_theme.dart';
import 'type_selector.dart';

class DropdownItem {
  final String id;
  final String name;
  DropdownItem({required this.id, required this.name});
}


final FirestoreService _firestoreService = FirestoreService.instance; 

class TransactionForm extends StatefulWidget {
  final User user;
  final Transaction? transactionToEdit;
  final bool isEditing;

  const TransactionForm({
    required this.user,
    this.transactionToEdit,
    super.key,
  }) : isEditing = transactionToEdit != null;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  late String _selectedType;
  DropdownItem? _selectedCategory; 
  late DateTime _selectedDate;
  
  bool _isSaving = false;
  String? _currencySymbol; 

  List<DropdownItem> _categories = [];

  StreamSubscription? _categorySubscription;

  @override
  void initState() {
    super.initState();
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    _currencySymbol = currencyProvider.currency.symbol;
    _startCategoryStream();
    _initializeForm();
  }

  

  void _initializeForm() {
    if (widget.isEditing && widget.transactionToEdit != null) {
      final transaction = widget.transactionToEdit!;
      _titleController.text = transaction.title;
      _amountController.text = _formatAmountForDisplay(transaction.amount);
      _selectedType = transaction.type;
      _selectedDate = transaction.date;
      
    } else {
      _selectedType = 'Expense';
      _selectedDate = DateTime.now();
    }
  }

  
  String _formatAmountForDisplay(double amount) {

    final formatted = amount.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
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

  void _startCategoryStream() {
    _categorySubscription = _firestoreService.streamCategories().listen((categories) {
      final dropdownItems = categories.map((c) => DropdownItem(id: c.id, name: c.name)).toList();
      
      setState(() {
        _categories = dropdownItems;
        
        if (widget.isEditing && 
            widget.transactionToEdit != null && 
            _selectedCategory == null) {
          final categoryId = widget.transactionToEdit!.categoryId;
          final existingCategory = dropdownItems.firstWhere(
            (item) => item.id == categoryId,
            orElse: () => dropdownItems.isNotEmpty ? dropdownItems.first : DropdownItem(id: '', name: 'Select Category'),
          );
          _selectedCategory = existingCategory.id.isNotEmpty ? existingCategory : null;
        } else if (!widget.isEditing && _selectedCategory == null && dropdownItems.isNotEmpty) {
          // Default to first category for new transactions
          _selectedCategory = dropdownItems.first;
        }
      });
    });
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing) {
        await _updateTransaction();
      } else {
        await _createTransaction();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _createTransaction() async {
    final amount = _parseAmount(_amountController.text);
    final theme = Theme.of(context);
    final uid = _firestoreService.currentUid;
    final cf = context.read<CurrencyProvider>().formatter;
    final messenger = ScaffoldMessenger.of(context);
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final newTransaction = Transaction(
      userId: uid,
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      categoryId: _selectedCategory!.id,
      date: _selectedDate,
    );

    await _firestoreService.addTransaction(newTransaction);
    
    if (mounted) {
      final formattedAmount = cf.format(amount);
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${newTransaction.title}" of $formattedAmount added successfully', 
            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: theme.colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
          
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateTransaction() async {
    if (widget.transactionToEdit == null) return;
    final theme = Theme.of(context);
    final cf = context.read<CurrencyProvider>().formatter;
    final messenger = ScaffoldMessenger.of(context);

    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final updatedTransaction = widget.transactionToEdit!.copyWith(
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      categoryId: _selectedCategory!.id,
      date: _selectedDate,
    );

    await _firestoreService.updateTransaction(updatedTransaction);
    
    if (mounted) {
      final formattedAmount = cf.format(amount);
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${updatedTransaction.title}" updated to $formattedAmount successfully'),
          duration: const Duration(seconds: 3),
          backgroundColor: theme.colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
          
        ),
      );
      Navigator.of(context).pop(updatedTransaction);
    }
  }

  void _handleError(dynamic error) {
    debugPrint('Transaction save error: $error');
    
    if (mounted) {
      String errorMessage = 'An error occurred';
      
      if (error is FirebaseException) {
        errorMessage = _getFirebaseErrorMessage(error);
      } else if (error is Exception) {
        errorMessage = error.toString();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to update this transaction';
      case 'not-found':
        return 'Transaction not found. It may have been deleted';
      case 'unavailable':
        return 'Network unavailable. Please check your connection';
      default:
        return error.message ?? 'Unknown error occurred';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categorySubscription?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final financialColors = theme.extension<FinancialColors>()!;
    final cf = context.watch<CurrencyProvider>().formatter;
    
    final isIncome = _selectedType == 'Income';
    final typeColor = isIncome ? financialColors.income : financialColors.expense;
    final isEditing = widget.isEditing;

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
                    isEditing ? 'Edit Transaction' : 'New Transaction',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 30),

                  // 1. REUSED WIDGET: Type Selector
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
                      labelText: 'Amount',
                      hintText: 'Enter amount',
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
                        return 'Please enter an amount';
                      }
                      
                      final amount = _parseAmount(value);
                      if (amount == null) {
                        return 'Please enter a valid number';
                      }
                      if (amount <= 0) {
                        return 'Amount must be greater than zero';
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
                      labelText: 'Title / Description',
                      hintText: 'e.g., Groceries, Salary, etc.',
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
                    validator: (value) => value == null || value.isEmpty ? 'Title cannot be empty' : null,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 20),
                  
                  // 2. REUSED WIDGET: Category Dropdown
                  CategoryDropdown(
                    selectedCategory: _selectedCategory,
                    categories: _categories,
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
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today, color: colors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
                        labelStyle: TextStyle(color: colors.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: colors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Save Button ---
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveTransaction,
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
                    child: _isSaving
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            isEditing ? 'UPDATE TRANSACTION' : 'SAVE TRANSACTION',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  
                  // Example preview (optional)
                  if (_amountController.text.isNotEmpty)
                    FutureBuilder<String>(
                      future: () async {
                        final amount = _parseAmount(_amountController.text);
                        if (amount == null || amount <= 0) return '';
                        return cf.format(amount);
                      }(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHigh.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: typeColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Preview: ${isIncome ? '+' : '-'}${snapshot.data}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: typeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
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