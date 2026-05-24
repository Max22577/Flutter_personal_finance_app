import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:personal_fin/core/shared_widgets/custom_appbar.dart';
import 'package:personal_fin/features/savings/views/widgets/currency_input_field.dart';
import 'package:personal_fin/features/savings/views/widgets/progress_chart.dart';
import 'package:personal_fin/models/savings.dart';
import 'package:provider/provider.dart';
import '../../view_models/set_goal_view_model.dart';

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


  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SetGoalViewModel(
        context.read<SavingsRepository>(),
        existingGoal: widget.existingGoal,
        exchangeService: context.read<ExchangeRateService>(),
      ),
      child: Consumer<SetGoalViewModel>(
        builder: (context, vm, _) {
          final lang = context.watch<LanguageProvider>();
          final colors = Theme.of(context).colorScheme;

          return Scaffold(
            backgroundColor: colors.surfaceContainerLow,
            appBar: CustomAppBar(
              title: vm.isEditing ? 'edit_goal' : 'set_savings_goal',
              isRootNav: false,
              actions: [
                if (vm.isEditing)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.error),
                    onPressed: () => _GoalActionHandler.confirmDelete(context, vm, widget.existingGoal!),
                    tooltip: lang.translate('delete_goal'),
                  ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!vm.isEditing) ...[
                    _GoalPreviewCard(
                      name: _nameController.text,
                      amount: _targetAmountController.text,
                      deadline: vm.deadline,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _GoalNameField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _GoalAmountField(
                    controller: _targetAmountController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _GoalDatePicker(vm: vm),
                  const SizedBox(height: 12),
                  _DeadlineBadge(deadline: vm.deadline),
                  const SizedBox(height: 32),
                  _SaveGoalButton(
                    formKey: _formKey,
                    vm: vm,
                    name: _nameController.text,
                    target: double.tryParse(_targetAmountController.text) ?? 0.0,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoalPreviewCard extends StatelessWidget {
  final String name;
  final String amount;
  final DateTime deadline;

  const _GoalPreviewCard({required this.name, required this.amount, required this.deadline});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currencyCode = context.watch<CurrencyProvider>().currency.code;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye, size: 20, color: colors.primary),
              const SizedBox(width: 8),
              Text(lang.translate('preview'), style: textTheme.titleSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressChartWidget(
            goal: SavingsGoal(
              name: name.isEmpty ? lang.translate('new_goal') : name,
              targetAmount: double.tryParse(amount) ?? 0,
              targetBaseAmount: 0,
              currentAmount: 0,
              currentBaseAmount: 0,
              deadline: deadline,
              currency: currencyCode,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineBadge extends StatelessWidget {
  final DateTime deadline;
  const _DeadlineBadge({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>();
    final days = deadline.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            '$days ${lang.translate('days_from_now')}',
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _GoalActionHandler {
  static Future<void> confirmDelete(BuildContext context, SetGoalViewModel vm, SavingsGoal goal) async {
    final lang = context.read<LanguageProvider>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('delete_goal')),
        content: Text('${lang.translate('delete_goal_confirm')} ${goal.name}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.translate('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.translate('delete'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await vm.deleteGoal();
      if (success && context.mounted) {
        Navigator.pop(context, goal.id);
      }
    }
  }

   static Future<void> selectDate(BuildContext context, SetGoalViewModel vm) async {
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

    if (picked != null) {
      vm.updateDeadline(picked); 
    }

  }
}

class _GoalNameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _GoalNameField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();

    return TextFormField(
      controller: controller,
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
      onChanged: onChanged,
    );

  }
}

class _GoalAmountField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _GoalAmountField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return CurrencyInputField(
      controller: controller,
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
      onChanged: onChanged,
    );
  }
}
  
class _GoalDatePicker extends StatelessWidget {
  final SetGoalViewModel vm;

  const _GoalDatePicker({required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();

     return GestureDetector(
      onTap: () => _GoalActionHandler.selectDate(context, vm),
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
}

class _SaveGoalButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final SetGoalViewModel vm;
  final String name;
  final double target;

  const _SaveGoalButton({
    required this.formKey,
    required this.vm,
    required this.name,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();
    final currencyCode = context.watch<CurrencyProvider>().currency.code;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: vm.isSaving ? null : () => _handleSave(context, currencyCode),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
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
                vm.isEditing 
                    ? lang.translate('update_goal_btn') 
                    : lang.translate('create_goal_btn'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimary,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, String currencyCode) async {
    if (!formKey.currentState!.validate()) return;

    final lang = context.read<LanguageProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      final success = await vm.saveGoal(name: name, target: target, currency: currencyCode);

      if (success && context.mounted) {
        AppFeedback.show(
          messenger, 
          lang.translate('goal_saved_successfully'), 
          colors: theme.colorScheme, 
          textTheme: theme.textTheme, 
          isError: false,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.show(
          messenger, 
          '${lang.translate('error')}: $e', 
          colors: theme.colorScheme, 
          textTheme: theme.textTheme, 
          isError: true,
        );
      }
    }
  }
}
  