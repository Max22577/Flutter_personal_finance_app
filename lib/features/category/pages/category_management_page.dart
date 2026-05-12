import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/widgets/animated_empty_state.dart';
import 'package:personal_fin/core/widgets/circular_icon_badge.dart'; 
import 'package:personal_fin/core/widgets/custom_appbar.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:personal_fin/features/category/widgets/category_form_handlers.dart';
import 'package:personal_fin/features/category/widgets/predefined_chip.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../view_models/category_view_model.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryViewModel(context.read<CategoryRepository>()),
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
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryViewModel>();
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: CustomAppBar(
        title: 'categories',
        isRootNav: false,
        actions: [
          _AppBarAction(icon: Icons.sort_rounded, onTap: () {}),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Predefined
          _SectionHeader(title: lang.translate('standard_categories')),
          SliverToBoxAdapter(child: _HorizontalCategoryList(vm: vm)),

          // Custom
          _SectionHeader(title: lang.translate('your_custom_categories')),
          _CustomCategorySliverList(vm: vm, lang: lang),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryFormHandlers.showAddSheet(context, vm),
        label: Text(lang.translate('new_category')),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _HorizontalCategoryList extends StatelessWidget {
  final CategoryViewModel vm;
  const _HorizontalCategoryList({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: vm.predefinedCategories.length,
        itemBuilder: (context, index) => PredefinedCategoryChip(
          category: vm.predefinedCategories[index],
          index: index,
        ),
      ),
    );
  }
}

class _CustomCategorySliverList extends StatelessWidget {
  final CategoryViewModel vm;
  final LanguageProvider lang;

  const _CustomCategorySliverList({required this.vm, required this.lang});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: vm.customCategoriesOnly,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: LoadingState());
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AnimatedEmptyState(
                message: lang.translate('no_custom_categories'),
                imagePath: 'assets/images/empty_wallet_light.svg',
                darkImagePath: 'assets/images/empty_wallet_dark1.svg',
                animationType: EmptyStateAnimation.bounce,
              )
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _CategoryTile(
                category: categories[index],
                onTap: () => CategoryFormHandlers.showEditDialog(context, categories[index], vm),
              ),
              childCount: categories.length,
            ),
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = Color(category.colorValue ?? colors.primary.toARGB32());
    final textScaler = MediaQuery.textScalerOf(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircularIconBadge( 
          textScaler: textScaler,
          icon: IconData(category.iconCode ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
          color: iconColor,
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.edit_outlined, size: 20, color: colors.outline),
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
        ),
        onPressed: onTap,
      ),
    );
  }
}