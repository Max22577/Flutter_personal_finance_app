import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:personal_fin/core/widgets/custom_appbar.dart';
import 'package:personal_fin/core/widgets/empty_state.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:personal_fin/features/category/widgets/predefined_chip.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../view_models/category_view_model.dart';
import 'package:personal_fin/core/utils/user_category_helper.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryViewModel(
        context.read<CategoryRepository>()
      ),
      child: const CategoryManagementView(),
    );
  }
}

class CategoryManagementView extends StatefulWidget {
  const CategoryManagementView({super.key});

  @override
  State<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<CategoryManagementView> {
  final _newCatController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = Colors.blue;


  // Helper for Snackbars 
  void _showFeedback(BuildContext context, String message, {bool isError = false}) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
          style: TextStyle(color: isError ? colors.onErrorContainer : colors.onPrimaryContainer),
        ),
        backgroundColor: isError ? colors.errorContainer : colors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Add New Category ---
  void _submitNewCategory(CategoryViewModel vm) async {
    if (_formKey.currentState!.validate()) {
      final lang = context.read<LanguageProvider>();
            
      try {
        final categoryName = _newCatController.text.trim();
        await vm.addCategory(
          name: _newCatController.text,
          iconCode: _selectedIcon.codePoint,
          colorValue: _selectedColor.toARGB32(),
          isCustom: true,
        );

        if (mounted) {
          _showFeedback(context, '${lang.translate('category_added_success')}: "$categoryName"', isError: false);
          _newCatController.clear(); // Clear the input field after success
        }
      } catch (e) {
        if (mounted) {
          _showFeedback(context, '${lang.translate('error_adding_category')}: $e', isError: true);           
        }
      }
    }
  }

  // --- Category Dialog ---
  void _showEditCategoryDialog(Category category, CategoryViewModel vm) {
    final TextEditingController editController = TextEditingController(text: category.name);
    final editFormKey = GlobalKey<FormState>();
    final lang = context.read<LanguageProvider>();
    int selectedIconCode = category.iconCode ?? Icons.category.codePoint;
    int selectedColorValue = category.colorValue ?? Colors.blue.toARGB32();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final selectedColor = Color(selectedColorValue);
          
          return AlertDialog(
            scrollable: true,
            title: Text(lang.translate('edit_category_name'), style: theme.textTheme.titleMedium),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- LIVE PREVIEW CARD ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selectedColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: selectedColor,
                          child: Icon(
                            IconData(selectedIconCode, fontFamily: 'MaterialIcons'),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            editController.text.isEmpty ? "Name" : editController.text,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- NAME INPUT ---
                  Form(
                  key: editFormKey,
                  child: TextFormField(
                    controller: editController,
                    onChanged: (v) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: lang.translate('new_name'),
                      hintText: lang.translate('enter_new_category_name'),
                      prefixIcon: Icon(Icons.edit, color: colors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
                      labelStyle: TextStyle(color: colors.primary),
                    ),
                    style: theme.textTheme.bodyLarge,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return lang.translate('name_empty_error');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // --- COLOR PICKER ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Color", style: theme.textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                _buildColorPicker(selectedColorValue, (color) {
                  setDialogState(() => selectedColorValue = color.toARGB32());
                }),
                const SizedBox(height: 12),

                // --- ICON PICKER ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Icon", style: theme.textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180, // Constrain the icon grid
                  width: double.maxFinite,
                  child: _buildIconPicker(selectedIconCode, selectedColor, (icon) {
                    setDialogState(() => selectedIconCode = icon.codePoint);
                  }),
                ),
              ],
            ),           
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(lang.translate('cancel'), style: TextStyle(color: colors.error)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (editFormKey.currentState!.validate()) {
                    final updatedName = editController.text.trim();
                    final updatedIcon = selectedIconCode;
                    final updatedColor = selectedColorValue;

                    final navigator = Navigator.of(context);

                    await vm.updateCategory(
                      id: category.id,
                      name: updatedName,
                      iconCode: updatedIcon,
                      colorValue: updatedColor,
                      isCustom: true,
                    );
                    if (!context.mounted) return;
                      _showFeedback(context, '${lang.translate('category_updated_to')} "$updatedName"', isError: false);
                    
                    navigator.pop(); // Close the dialog
                    
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                child: Text(lang.translate('save_changes')),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  void _showAddCategorySheet(CategoryViewModel vm) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.read<LanguageProvider>();


    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ClipRRect(
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
              child: SafeArea( 
                top: false, 
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView( 
                    child: Form(
                      key: _formKey,
                      child: StatefulBuilder( // Use StatefulBuilder to update state inside the sheet
                        builder: (context, setSheetState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                              const SizedBox(height: 20),
                              Center(
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _selectedColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(_selectedIcon, color: _selectedColor, size: 40),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _newCatController.text.isEmpty ? "Category Name" : _newCatController.text,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _newCatController,
                                autofocus: true,
                                onChanged: (v) => setSheetState(() {}),
                                decoration: InputDecoration(
                                  hintText: lang.translate('category_name'),
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),),
                                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                ),
                                validator: (v) => v!.isEmpty ? lang.translate('name_empty_error') : null,
                              ),
                              const SizedBox(height: 24),

                              Text("Select Color", style: theme.textTheme.labelLarge),
                              const SizedBox(height: 12),
                              _buildColorPicker(_selectedColor.toARGB32(), (color) {
                                setSheetState(() => _selectedColor = color);
                              }),

                              const SizedBox(height: 24),
                              Text("Select Icon", style: theme.textTheme.labelLarge),
                              const SizedBox(height: 12),
                              // Constrain the GridView height
                              SizedBox(
                                height: 200, 
                                child: SingleChildScrollView(
                                  child: _buildIconPicker(_selectedIcon.codePoint, _selectedColor, (icon) {
                                    setSheetState(() => _selectedIcon = icon);
                                  }),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _submitNewCategory(vm);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                  child: Text(lang.translate('create_category')),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(int selectedValue, Function(Color) onSelected) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: availableColors.map((color) {
        final isSelected = selectedValue == color.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(color),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconPicker(int selectedCode, Color activeColor, Function(IconData) onSelected) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: availableIcons.length,
      itemBuilder: (context, i) {
        final icon = availableIcons[i];
        final isSelected = selectedCode == icon.codePoint;
        return GestureDetector(
          onTap: () => onSelected(icon),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: CustomAppBar(
        title: 'categories',
        isRootNav: false,  
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.sort_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: const CircleBorder(),
              ),
              onPressed: () {}, // Optional: Add sorting logic
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(lang.translate('standard_categories'), theme, colors),
            _buildPredefinedList(vm),
            _buildSectionHeader(lang.translate('your_custom_categories'), theme, colors),
            _buildCustomList(vm, lang, colors, textTheme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategorySheet(vm),
        label: Text(lang.translate('new_category')),
        icon: const Icon(Icons.add),
        elevation: 3,
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colors.outline,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildPredefinedList(CategoryViewModel vm) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: vm.predefinedCategories.length,
        itemBuilder: (context, index) {
          return PredefinedCategoryChip(
            category: vm.predefinedCategories[index],
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildCustomList(CategoryViewModel vm, LanguageProvider lang, ColorScheme colors, TextTheme textTheme) {
    return StreamBuilder<List<Category>>(
      stream: vm.customCategoriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: LoadingState());
        if (snapshot.hasError) {
          return Center(
            child: EmptyState(
              icon: Icons.error_outline,
              title:(lang.translate('error_loading')),
              message: vm.errorMessage!,
              actionText: lang.translate('retry'),
              onAction: () => vm.refreshCategories(),
            ),
          );
        }
        
        final categories = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return _buildCategoryTile(
              category, 
              colors, 
              textTheme, 
              vm,
              key: ValueKey('${category.id}_${category.name}_${category.iconCode}'), // Forces rebuild if these change
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryTile(Category category, ColorScheme colors, TextTheme textTheme, CategoryViewModel vm, {required Key key}) {
    final icon = CategoryIconHelper.getIcon(category);
    final color = CategoryIconHelper.getColor(category, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0, left: 16.0, right: 16.0),      
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.4),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          category.name,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5,),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant,),
        onTap: () => _showEditCategoryDialog(category, vm),
      ),
    );
  }

}