import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/core/widgets/savings/currency_input_field.dart';
import 'package:personal_fin/core/widgets/savings/progress_chart.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:personal_fin/models/savings.dart';


class SetGoalPage extends StatefulWidget {
  final SavingsGoal? existingGoal;

  const SetGoalPage({this.existingGoal, super.key});

  @override
  State<SetGoalPage> createState() => _SetGoalPageState();
}

class _SetGoalPageState extends State<SetGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  late DateTime _selectedDeadline;
  bool _isSaving = false;
  final FirestoreService _firestoreService = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingGoal != null) {
      _nameController.text = widget.existingGoal!.name;
      _targetAmountController.text = widget.existingGoal!.targetAmount.toString();
      _selectedDeadline = widget.existingGoal!.deadline;
    } else {
      _selectedDeadline = DateTime.now().add(const Duration(days: 30));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
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
    
    if (picked != null && picked != _selectedDeadline) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    debugPrint('DEBUG: Starting save operation...');

    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    try {
      final goal = SavingsGoal(
        id: widget.existingGoal?.id,
        name: _nameController.text.trim(),
        targetAmount: double.parse(_targetAmountController.text),
        currentAmount: widget.existingGoal?.currentAmount ?? 0.0,
        deadline: _selectedDeadline,
      );

      if (widget.existingGoal != null) {
        debugPrint('DEBUG: Calling updateSavingsGoal');
        await _firestoreService.updateSavingsGoal(goal);
      } else {
        debugPrint('DEBUG: Calling addSavingsGoal');
        await _firestoreService.addSavingsGoal(goal);
      }
      debugPrint('DEBUG: Save operation completed successfully.');

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.existingGoal != null 
                ? 'Goal updated successfully!' 
                : 'Goal created successfully!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            backgroundColor: theme.colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
        if (widget.existingGoal != null) {
          Navigator.of(context).pop(goal); 
        } else {
          Navigator.of(context).pop();
        }
         
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGoal != null;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Goal' : 'Set Savings Goal',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onPrimary,
          ),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: colors.error,
              ),
              onPressed: _deleteGoal,
              tooltip: 'Delete Goal',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.existingGoal == null) ...[
                _buildGoalPreview(context),
                const SizedBox(height: 24),
              ],

              // Goal Name
              TextFormField(
                controller: _nameController,
                style: textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                  hintText: 'e.g., New Car, Vacation, Emergency Fund',
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
                    return 'Please enter a goal name';
                  }
                  if (value.length < 3) {
                    return 'Goal name must be at least 3 characters';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Target Amount with CurrencyInputField
              CurrencyInputField(
                controller: _targetAmountController,
                labelText: 'Target Amount',
                
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  if (amount > 10000000) {
                    return 'Amount is too large';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Deadline Selection
              GestureDetector(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Target Date',
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
                    fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDeadline),
                        style: textTheme.bodyLarge,
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
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
                      '${_selectedDeadline.difference(DateTime.now()).inDays} days from now',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button with theme
              ElevatedButton(
                onPressed: _isSaving ? null : _saveGoal,
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
                child: _isSaving
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : Text(
                        isEditing ? 'UPDATE GOAL' : 'CREATE GOAL',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: colors.onPrimary,
                        ),
                      ),
              ),

              // Quick Amount Suggestions - only for new goals
              if (!isEditing) ...[
                const SizedBox(height: 32),
                _buildQuickAmounts(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    final targetAmount = double.tryParse(_targetAmountController.text) ?? 0;
    final goalName = _nameController.text.isEmpty ? 'New Goal' : _nameController.text;

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
                'Preview',
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
              deadline: _selectedDeadline,
              
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Targets',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to set amount:',
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [500, 1000, 2500, 5000, 10000, 25000].map((amount) {
            return FilterChip(
              label: CurrencyDisplay(
                amount: amount.toDouble(),
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                compact: amount >= 1000,
              ),
              selected: double.tryParse(_targetAmountController.text) == amount.toDouble(),
              onSelected: (_) {
                _targetAmountController.text = amount.toString();
                setState(() {});
              },
              backgroundColor: colors.surfaceContainerHighest,
              selectedColor: colors.primary.withValues(alpha: 0.2),
              checkmarkColor: colors.primary,
              labelStyle: textTheme.labelMedium?.copyWith(
                color: double.tryParse(_targetAmountController.text) == amount.toDouble()
                    ? colors.primary
                    : colors.onSurface,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: double.tryParse(_targetAmountController.text) == amount.toDouble()
                      ? colors.primary
                      : colors.outline.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _deleteGoal() async {
    if (widget.existingGoal == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Goal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.existingGoal!.name}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
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
              'Delete',
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
        await _firestoreService.deleteSavingsGoal(widget.existingGoal!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Goal deleted successfully!"),
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
              content: Text('Delete failed: ${e.toString()}'),
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
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }
}