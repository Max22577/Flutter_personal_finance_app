import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:personal_fin/features/savings/view_models/add_to_savings_view_model.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';

class AddSavingsSheetContent extends StatefulWidget {
  final SavingsGoal goal;
  final VoidCallback? onSuccess;

  const AddSavingsSheetContent({super.key, required this.goal, this.onSuccess});

  @override
  State<AddSavingsSheetContent> createState() => AddSavingsSheetContentState();
}

class AddSavingsSheetContentState extends State<AddSavingsSheetContent> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final currencySymbol = context.watch<CurrencyProvider>().currency.symbol;
    final currencyCode = context.watch<CurrencyProvider>().currency.code;

    return ChangeNotifierProvider(
      create: (context) => AddToSavingsViewModel(context.read<SavingsRepository>()),
      child: Consumer<AddToSavingsViewModel>(
        builder: (context, vm, _) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetGrabber(),
                  const SizedBox(height: 20),
                  _SheetHeader(goalName: widget.goal.name),
                  const SizedBox(height: 24),
                  
                  // Amount Input
                  _CustomTextField(
                    controller: _amountController,
                    label: lang.translate('amount'),
                    prefixText: '$currencySymbol ',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateAmount(v, lang),
                  ),
                  const SizedBox(height: 16),
                  
                  // Note Input
                  _CustomTextField(
                    controller: _noteController,
                    label: lang.translate('note_optional'),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 24),
                  
                  _SubmitButton(
                    isProcessing: vm.isProcessing,
                    onPressed: () => _handleSave(vm, context, currencyCode),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Logic Helpers ---
  String? _validateAmount(String? value, LanguageProvider lang) {
    if (value == null || value.isEmpty) return lang.translate('required');
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) return lang.translate('err_invalid_amount');
    return null;
  }

  Future<void> _handleSave(AddToSavingsViewModel vm, BuildContext context, String currencyCode) async {
    if (!_formKey.currentState!.validate()) return;

    final lang = context.read<LanguageProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    try{
      final success = await vm.addToGoal(
        goalId: widget.goal.id!,
        amount: double.parse(_amountController.text),
        currency: currencyCode,
        note: _noteController.text,
        defaultNote: '${lang.translate('added_to')} ${widget.goal.name}',
      );

      if (success && context.mounted) {
        Navigator.pop(context);
        AppFeedback.show(messenger, '${lang.translate('added_to')} ${widget.goal.name}', colors: colors, textTheme: textTheme, isError: false);
        widget.onSuccess?.call();
      }
    } catch(e) {
      if(context.mounted) {
        AppFeedback.show(messenger, '${lang.translate('error')}: ${e.toString()}', colors: colors, textTheme: textTheme, isError:true);
      }
    }
  }

}

class _SheetGrabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32, height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? prefixText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;

  const _CustomTextField({
    required this.controller,
    required this.label,
    this.prefixText,
    this.keyboardType,
    this.validator,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String goalName;

  const _SheetHeader({required this.goalName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('add_to_savings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${lang.translate('adding_to')}: $goalName',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();

    return SizedBox(
      width: double.infinity,
      height: 56, 
      child: ElevatedButton(
        onPressed: isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isProcessing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.onPrimary,
              ),
            )
          : Text(
              lang.translate('add'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.onPrimary,
              ),
            ),
      ),
    );
  }
}