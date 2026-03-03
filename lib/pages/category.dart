import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/category/predefined_chip.dart';
import 'package:provider/provider.dart';
import '../core/services/firestore_service.dart';
import '../models/category.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newCategoryController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService.instance;

  // --- Add New Category ---
  void _submitNewCategory() async {
    if (_formKey.currentState!.validate()) {
      final lang = context.read<LanguageProvider>();
            
      try {
        final categoryName = _newCategoryController.text.trim();
        await _firestoreService.addCategory(categoryName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang.translate('category_added_success'), 
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(20),
              duration: const Duration(seconds: 3),
            ),
          );
          _newCategoryController.clear(); // Clear the input field after success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${lang.translate('error_adding_category')}: $e',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)
              ),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(20),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // --- Category Dialog ---
  void _showEditCategoryDialog(Category category) {
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

                  await _firestoreService.updateCategoryName(category.id, newName);
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

  void _showAddCategorySheet() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.read<LanguageProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => Padding(
        // This pushes the entire sheet up when the keyboard appears
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
                            controller: _newCategoryController,
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
                                _submitNewCategory();
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                lang.translate('standard_categories'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.outline,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _firestoreService.predefinedCategories.length,
                itemBuilder: (context, index) {
                  return PredefinedCategoryChip(
                    category: _firestoreService.predefinedCategories[index],
                    index: index,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                lang.translate('your_custom_categories'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.outline,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            StreamBuilder<List<Category>>(
              stream: _firestoreService.streamCustomCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang.translate('error_loading_categories'),
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final customCategories = snapshot.data ?? [];

                if (customCategories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: colors.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang.translate('no_custom_categories'),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.translate('add_first_category'),
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
               
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), 
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customCategories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = customCategories[index];
                    return _buildCategoryTile(context, category, colors, textTheme);
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'category_add',
        onPressed: _showAddCategorySheet,
        icon: const Icon(Icons.add_rounded),
        label: Text(lang.translate('new_category')),
        elevation: 3,
      ),         
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category, ColorScheme colors, TextTheme textTheme) {
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
        onTap: () => _showEditCategoryDialog(category),
      ),
    );
  }
}