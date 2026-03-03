// lib/features/savings/widgets/add_to_savings_button.dart
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/services/savings_service.dart';
import 'package:provider/provider.dart';

import '../../../models/savings.dart';

class AddToSavingsButton extends StatefulWidget {
  final SavingsGoal goal;
  final VoidCallback? onSuccess;

  const AddToSavingsButton({
    required this.goal,
    this.onSuccess,
    super.key,
  });

  @override
  State<AddToSavingsButton> createState() => _AddToSavingsButtonState();
}

class _AddToSavingsButtonState extends State<AddToSavingsButton> {
  final SavingsService _savingsService = SavingsService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _showAddToSavingsDialog() async {
    final lang = context.read<LanguageProvider>();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(lang.translate('add_to_savings')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${lang.translate('adding_to')}: ${widget.goal.name}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration:  InputDecoration(
                    labelText: lang.translate('amount'),
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return lang.translate('required');
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return lang.translate('err_invalid_amount');
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: lang.translate('note_optional'),
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: _isProcessing ? null : _addToSavings,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  :  Text(lang.translate('add')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToSavings() async {
    final lang = context.read<LanguageProvider>();
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isProcessing = true);

    try {
      await _savingsService.addToSavingsGoal(
        goalId: widget.goal.id!,
        amount: amount,
        transactionNote: _noteController.text.isNotEmpty
            ? _noteController.text
            : '${lang.translate('added_to')} ${widget.goal.name}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\$${amount.toStringAsFixed(2)} ${lang.translate('added_to')} ${widget.goal.name}',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
        
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lang.translate('error')}: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _amountController.clear();
        _noteController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();
    
    return FloatingActionButton.extended(
      heroTag: 'add_to_savings_${widget.goal.id}',
      icon: const Icon(Icons.add, size: 18,),
      label: Text(lang.translate('add_to_savings'), 
        style: theme.textTheme.labelLarge?.copyWith(
          letterSpacing: -0.05,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 32, 119, 24),
      onPressed: _showAddToSavingsDialog,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}