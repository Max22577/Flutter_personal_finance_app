import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/widgets/shared/custom_appbar.dart';
import 'package:personal_fin/features/savings/widgets/currency_input_field.dart';
import 'package:personal_fin/features/savings/widgets/progress_chart.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';
import '../view_models/set_goal_view_model.dart';

class SetGoalPage extends StatefulWidget {
  final SavingsGoal? existingGoal;
  const SetGoalPage({this.existingGoal, super.key});

  @override
  State<SetGoalPage> createState() => _SetGoalPageState();
}

class _SetGoalPageState extends State<SetGoalPage> {
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingGoal?.name ?? '');
    _targetAmountController = TextEditingController(text: widget.existingGoal?.targetAmount.toString() ?? '');
  }

  Future<void> _selectDate(BuildContext context, SetGoalViewModel vm) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: vm.deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != vm.deadline) {
      setState(() => vm.deadline = picked);
    }
  }

  Future<void> _deleteGoal(SetGoalViewModel vm) async {
    if (widget.existingGoal == null) return;
    final lang = context.read<LanguageProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          lang.translate('delete_goal'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        content: Text(
          '${lang.translate('delete_goal_confirm')} ${widget.existingGoal!.name}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang.translate('cancel'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              lang.translate('delete'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final result = await vm.deleteGoal();
        if (mounted && result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang.translate('goal_deleted_successfully')),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.of(context).pop(widget.existingGoal!.id!);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${lang.translate('delete_failed')} $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SetGoalViewModel(SavingsRepository(), existingGoal: widget.existingGoal),
      child: Consumer<SetGoalViewModel>(
        builder: (context, vm, child) {
          final lang = context.watch<LanguageProvider>();
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final textTheme = theme.textTheme;
          
          return Scaffold(
            backgroundColor: colors.surfaceContainerLow,
            appBar: CustomAppBar(
              title: vm.isEditing ? 'edit_goal' : 'set_savings_goal',
              isRootNav: false,
              actions: [
                if (vm.isEditing)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colors.error,
                    ),
                    onPressed: () => _deleteGoal(vm),
                    tooltip: lang.translate('delete_goal'),
                  ),
              ],
            ),           
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.existingGoal == null) ...[
                    _buildGoalPreview(context, vm, lang, colors, textTheme),
                    const SizedBox(height: 24),
                  ],
                  _buildNameField(vm, lang, colors, textTheme),
                  const SizedBox(height: 20),
                  _buildAmountField(vm, lang),
                  const SizedBox(height: 20),
                  _buildDatePicker(context, vm, lang, colors, textTheme),
                  const SizedBox(height: 12),
              
                  // Days counter with theme integration
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${vm.deadline.difference(DateTime.now()).inDays} ${lang.translate('days_from_now')}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSaveButton(context, vm, lang, colors, textTheme),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // UI Helper Methods...
  Widget _buildGoalPreview(BuildContext context, SetGoalViewModel vm, LanguageProvider lang, ColorScheme colors, TextTheme textTheme) {

    final targetAmount = double.tryParse(_targetAmountController.text) ?? 0;
    final goalName = _nameController.text.isEmpty ? lang.translate('new_goal') : _nameController.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.remove_red_eye,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                lang.translate('preview'),
                style: textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressChartWidget(
            goal: SavingsGoal(
              name: goalName,
              targetAmount: targetAmount,
              currentAmount: 0,
              deadline: vm.deadline,
              
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNameField(SetGoalViewModel vm, LanguageProvider lang, ColorScheme colors, TextTheme textTheme) {
    return TextFormField(
      controller: _nameController,
      style: textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: lang.translate('goal_name'),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.7),
        ),
        hintText: lang.translate('goal_hint'),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          Icons.flag,
          color: colors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        filled: true,
        fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return lang.translate('err_no_name');
        }
        if (value.length < 3) {
          return lang.translate('err_name_short');
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }
  Widget _buildAmountField(SetGoalViewModel vm, LanguageProvider lang) {
    return CurrencyInputField(
      controller: _targetAmountController,
      labelText: lang.translate('target_amount'),
      
      validator: (value) {
        if (value == null || value.isEmpty) {
          return lang.translate('err_no_amount');
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return lang.translate('err_invalid_amount');
        }
        if (amount > 10000000) {
          return lang.translate('err_amount_large');
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }
  Widget _buildDatePicker(BuildContext context, SetGoalViewModel vm, LanguageProvider lang, ColorScheme colors, TextTheme textTheme) {
    return GestureDetector(
      onTap: () => _selectDate(context, vm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: lang.translate('target_date'),
          labelStyle: textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(
            Icons.calendar_today,
            color: colors.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.outline),
          ),
          filled: true,
          fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat.yMMMMd(lang.localeCode).format(vm.deadline),
              style: textTheme.bodyLarge,
            ),
            Icon(
              Icons.arrow_drop_down,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSaveButton(BuildContext context, SetGoalViewModel vm, LanguageProvider lang, ColorScheme colors, TextTheme textTheme) {
    final navigator = Navigator.of(context);
    return ElevatedButton(
      onPressed: vm.isSaving ? null : () async {
        if (_formKey.currentState!.validate()) {
          final name = _nameController.text;
          final target = double.tryParse(_targetAmountController.text) ?? 0.0;
          final success = await vm.saveGoal(name: name, target: target);
          if (success && mounted) navigator.pop();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: colors.primary.withValues(alpha: 0.3),
      ),
      child: vm.isSaving
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.onPrimary,
            ),
          )
        : Text(
            vm.isEditing ? lang.translate('update_goal_btn') : lang.translate('create_goal_btn'),
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.onPrimary,
            ),
          ),
    );
  }
}