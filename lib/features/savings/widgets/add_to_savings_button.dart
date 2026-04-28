import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
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

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSuccess(BuildContext context, double amount, String goalName, String successMsg) {
    Navigator.pop(context); // Close Bottom sheet
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
  Future<void> _showAddMoneySheet(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final currencySymbol = context.read<CurrencyProvider>().currency.symbol;
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to push up when the keyboard appears
      useSafeArea: true,
      builder: (bottomSheetContext) => ChangeNotifierProvider(
        create: (context) => AddToSavingsViewModel(context.read<SavingsRepository>()),
        child: Consumer<AddToSavingsViewModel>(
          builder: (context, vm, _) => Padding(
            // Forces the padding to respect the on-screen keyboard
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView( // Prevents overflow on small phones
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Grab Handle at top
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 32, height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(lang.translate('add_to_savings'), 
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: lang.translate('amount'),
                        prefixText: '$currencySymbol ',
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return lang.translate('required');
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) return lang.translate('err_invalid_amount');
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Note Input
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: lang.translate('note_optional'),
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),

                    // Actions (Full Width button is much more modern for forms)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: vm.isProcessing ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            try {
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
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('${lang.translate('error')}: $e',
                                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                                  ),
                                  backgroundColor: theme.colorScheme.errorContainer,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: vm.isProcessing
                          ? CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary)                          
                          : Text(lang.translate('add'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return FilledButton.icon(
      onPressed: () => _showAddMoneySheet(context),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(lang.translate('add')),
    );
  }
}