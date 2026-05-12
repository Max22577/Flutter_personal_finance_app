import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/utils/app_feedback.dart';
import 'package:personal_fin/core/utils/user_category_helper.dart';
import 'package:personal_fin/features/category/view_models/category_view_model.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';

class CategoryFormHandlers {
  /// --- ADD CATEGORY SHEET ---
  static void showAddSheet(BuildContext context, CategoryViewModel vm) {
    final theme = Theme.of(context);
    final lang = context.read<LanguageProvider>();
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    IconData selectedIcon = Icons.category;
    Color selectedColor = Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _FormSheetWrapper(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LivePreviewHeader(
                  icon: selectedIcon,
                  color: selectedColor,
                  label: controller.text.isEmpty ? "New Category" : controller.text,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (v) => setSheetState(() {}),
                  decoration: InputDecoration(
                    hintText: lang.translate('category_name'),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (v) => v!.isEmpty ? lang.translate('name_empty_error') : null,
                ),
                const SizedBox(height: 24),
                _ColorPicker(
                  selectedColor: selectedColor,
                  onSelected: (color) => setSheetState(() => selectedColor = color),
                ),
                const SizedBox(height: 24),
                _IconPicker(
                  selectedIcon: selectedIcon,
                  activeColor: selectedColor,
                  onSelected: (icon) => setSheetState(() => selectedIcon = icon),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleCreate(context, vm, controller, selectedIcon, selectedColor),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(lang.translate('create_category')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --- EDIT CATEGORY DIALOG ---
  static void showEditDialog(BuildContext context, Category category, CategoryViewModel vm) {
    final lang = context.read<LanguageProvider>();
    final controller = TextEditingController(text: category.name);
    final formKey = GlobalKey<FormState>();
    
    int selectedIconCode = category.iconCode ?? Icons.category.codePoint;
    int selectedColorValue = category.colorValue ?? Colors.blue.toARGB32();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedColor = Color(selectedColorValue);
          
          return AlertDialog(
            scrollable: true,
            title: Text(lang.translate('edit_category_name')),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LivePreviewHeader(
                    icon: IconData(selectedIconCode, fontFamily: 'MaterialIcons'),
                    color: selectedColor,
                    label: controller.text,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    onChanged: (v) => setDialogState(() {}),
                    decoration: InputDecoration(labelText: lang.translate('new_name')),
                    validator: (v) => v!.isEmpty ? lang.translate('name_empty_error') : null,
                  ),
                  const SizedBox(height: 20),
                  _ColorPicker(
                    selectedColor: selectedColor,
                    onSelected: (c) => setDialogState(() => selectedColorValue = c.toARGB32()),
                  ),
                  const SizedBox(height: 20),
                  _IconPicker(
                    selectedIcon: IconData(selectedIconCode, fontFamily: 'MaterialIcons'),
                    activeColor: selectedColor,
                    onSelected: (i) => setDialogState(() => selectedIconCode = i.codePoint),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.translate('cancel'))),
              ElevatedButton(
                onPressed: () => _handleUpdate(context, vm, category.id, controller, selectedIconCode, selectedColorValue),
                child: Text(lang.translate('save_changes')),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- SUBMISSION LOGIC ---

  static Future<void> _handleCreate(BuildContext context, CategoryViewModel vm, TextEditingController controller, IconData icon, Color color) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    await vm.saveCategory(
      name: controller.text.trim(),
      iconCode: icon.codePoint,
      colorValue: color.toARGB32(),
    );
    if (context.mounted) { 
      AppFeedback.show(messenger, 'Catgegory successfully added', colors: colors, textTheme: textTheme, isError: false);
      Navigator.pop(context);
    }
  }

  static Future<void> _handleUpdate(BuildContext context, CategoryViewModel vm, String id, TextEditingController controller, int icon, int color) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    await vm.saveCategory(
      id: id,
      name: controller.text.trim(),
      iconCode: icon,
      colorValue: color,
    );
    if (context.mounted) {
      AppFeedback.show(messenger, 'Catgegory successfully updated', colors: colors, textTheme: textTheme, isError: true);
      Navigator.pop(context);
    }
  }
}

class _FormSheetWrapper extends StatelessWidget {
  final Widget child;
  const _FormSheetWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: SafeArea(child: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
  }
}

class _LivePreviewHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LivePreviewHeader({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 40),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onSelected;

  const _ColorPicker({required this.selectedColor, required this.onSelected});

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Color", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableColors.map((color) {
            final isSelected = selectedColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => onSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _IconPicker extends StatelessWidget {
  final IconData selectedIcon;
  final Color activeColor;
  final ValueChanged<IconData> onSelected;

  const _IconPicker({
    required this.selectedIcon, 
    required this.activeColor, 
    required this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Icon", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 180, // Fixed height for the grid within the scrollable sheet
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (context, i) {
              final icon = availableIcons[i];
              final isSelected = selectedIcon.codePoint == icon.codePoint;
              
              return GestureDetector(
                onTap: () => onSelected(icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? activeColor : Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}