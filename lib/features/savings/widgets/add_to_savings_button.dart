import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/features/savings/view_models/add_to_savings_view_model.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';

class AddToSavingsButton extends StatefulWidget {
  final SavingsGoal goal;
  final VoidCallback? onSuccess;

  const AddToSavingsButton({required this.goal, this.onSuccess, super.key});

  @override
  State<AddToSavingsButton> createState() => _AddToSavingsButtonState();
}

class _AddToSavingsButtonState extends State<AddToSavingsButton> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _handleSuccess(BuildContext context, double amount, String goalName, String successMsg) {
    Navigator.pop(context); // Close Dialog
    _amountController.clear();
    _noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: 
        Text('\$$amount $successMsg $goalName',
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

  // UI Dialog logic remains here, but calling VM for data
  Future<void> _showDialog(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider(
        create: (_) => AddToSavingsViewModel(),
        child: Consumer<AddToSavingsViewModel>(
          builder: (context, vm, _) => AlertDialog(
            title: Text(context.read<LanguageProvider>().translate('add_to_savings')),
            content: Form(
              key: _formKey,
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: vm.isProcessing ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final lang = context.read<LanguageProvider>();
                      
                      final amount = double.parse(_amountController.text);
                      
                      final success = await vm.addToGoal(
                        goalId: widget.goal.id!,
                        amount: amount,
                        note: _noteController.text,
                        defaultNote: '${lang.translate('added_to')} ${widget.goal.name}',
                      );

                      if (!context.mounted) return;

                      if (success) {                       
                        _handleSuccess(context, amount, widget.goal.name, lang.translate('added_to'));
                      }
                    } catch (e) {
                      // Show Error SnackBar
                      if (mounted) {
                       messenger.showSnackBar(
                          SnackBar(
                            content: Text('${lang.translate('error')}: $e',
                              style: TextStyle(color: theme.colorScheme.onErrorContainer),
                            ),
                            backgroundColor: theme.colorScheme.errorContainer,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.all(20),
                          ),
                        );
                      }
                    }
                  }
                },
                child: vm.isProcessing
                 ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(lang.translate('add')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();

    return FloatingActionButton.extended(
      onPressed: () => _showDialog(context),
      icon: const Icon(Icons.add, size: 18,),
      label: Text(lang.translate('add_to_savings'), 
        style: theme.textTheme.labelLarge?.copyWith(
          letterSpacing: -0.05,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 32, 119, 24),
    );
  }
}