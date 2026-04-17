import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/features/category/pages/category_management_page.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/models/category.dart';
import '../../../helpers/test_nav_helpers.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late TestNavigationDependencyManager tdm;
  late MockCategoryRepository mockRepo;

  setUp(() {
    tdm = TestNavigationDependencyManager();
    mockRepo = MockCategoryRepository();

    // Stub the stream to return an empty list by default
    when(() => mockRepo.predefinedCategories).thenReturn([]);
    when(() => mockRepo.customCategoriesStream)
        .thenAnswer((_) => Stream.value([]));
    when(() => mockRepo.categoriesStream)
        .thenAnswer((_) => Stream.value([]));
  });

  Widget buildTestWidget() {
    return tdm.wrap(
      Provider<CategoryRepository>.value(
        value: mockRepo,
        child: const CategoryManagementPage(),
      ),
    );
  }

  group('CategoryManagementPage UI Tests', () {
    testWidgets('renders predefined and custom category sections', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('standard_categories'), findsOneWidget);
      expect(find.text('your_custom_categories'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays custom categories from the stream', (tester) async {
      final categories = [
        Category(id: 'c1', name: 'Freelance'),
        Category(id: 'c2', name: 'Rent'),
      ];

      when(() => mockRepo.customCategoriesStream)
          .thenAnswer((_) => Stream.value(categories));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(); // Start stream

      expect(find.text('Freelance'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
    });
  });

  group('Category Actions', () {
    testWidgets('opens bottom sheet and adds a new category', (tester) async {
      when(() => mockRepo.addCategory(any())).thenAnswer((_) async => {});
      
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); 

      expect(find.text('new_category'), findsNWidgets(2)); // Title and FAB label

      await tester.enterText(find.byType(TextFormField), 'Investment');
      
      await tester.tap(find.text('create_category'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.addCategory('Investment')).called(1);
      
      expect(find.textContaining('category_added_success'), findsOneWidget);
    });

    testWidgets('opens edit dialog and updates category name', (tester) async {
      final category = Category(id: 'c1', name: 'Old Name');
      
      when(() => mockRepo.customCategoriesStream)
          .thenAnswer((_) => Stream.value([category]));
      when(() => mockRepo.updateCategory(any(), any())).thenAnswer((_) async => {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('Old Name'));
      await tester.pumpAndSettle();

      expect(find.text('edit_category_name'), findsOneWidget);

      // Clear and enter new name
      await tester.enterText(find.widgetWithText(TextFormField, 'Old Name'), 'New Name');
      
      // Save
      await tester.tap(find.text('save_changes'));
      await tester.pumpAndSettle();

      // Verify repo was called correctly
      verify(() => mockRepo.updateCategory('c1', 'New Name')).called(1);
    });
  });
}