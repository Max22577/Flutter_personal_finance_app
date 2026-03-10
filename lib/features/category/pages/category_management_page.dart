import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/features/category/widgets/predefined_chip.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../view_models/category_view_model.dart';

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

  // Helper for Snackbars to avoid repetition
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
        await vm.addCategory(categoryName);

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

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        
        return AlertDialog(
          title: Text(lang.translate('edit_category_name'), style: theme.textTheme.titleMedium),
          content: Form(
            key: editFormKey,
            child: TextFormField(
              controller: editController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: lang.translate('new_name'),
                hintText: lang.translate('enter_new_category_name'),
                prefixIcon: Icon(Icons.edit, color: colors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(lang.translate('cancel'), style: TextStyle(color: colors.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (editFormKey.currentState!.validate()) {
                  final newName = editController.text.trim();

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final theme = Theme.of(context);

                  await vm.updateCategory(category.id, newName);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('${lang.translate('category_updated_to')} "$newName"', 
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer)
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(20),
                      duration: const Duration(seconds: 3),
                    ),
                  );
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                          const SizedBox(height: 20),
                          Text(lang.translate('new_category'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _newCatController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: lang.translate('category_name'),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),),
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            ),
                            validator: (v) => v!.isEmpty ? lang.translate('name_empty_error') : null,
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(lang.translate('categories'), 
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onPrimary,
          ),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () {}, // Optional: Add sorting logic
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
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
        if (snapshot.hasError) return Text(lang.translate('error_loading'));
        
        final categories = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return _buildCategoryTile(category, colors, textTheme, vm);
          },
        );
      },
    );
  }

  Widget _buildCategoryTile(Category category, ColorScheme colors, TextTheme textTheme, CategoryViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer.withValues(alpha: 0.4),
          child: Text(
            category.name.characters.first.toUpperCase(),
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          category.name,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showEditCategoryDialog(category, vm),
      ),
    );
  }

}