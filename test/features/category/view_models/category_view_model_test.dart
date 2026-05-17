import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/features/category/view_models/category_view_model.dart';
import 'package:personal_fin/models/category.dart';


class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late CategoryViewModel viewModel;
  late MockCategoryRepository mockCatRepo;

  final samplePredefinedCategories = [
    Category(id: 'cat_food', name: 'Food', iconCode: 123, colorValue: 456, isCustom: false),
    Category(id: 'cat_rent', name: 'Rent', iconCode: 789, colorValue: 101, isCustom: false),
  ];

  final sampleCustomCategories = [
    Category(id: 'cat_custom_1', name: 'Hobbies', iconCode: 111, colorValue: 222, isCustom: true),
  ];

  setUpAll(() {
    registerFallbackValue(Category(
      id: '',
      name: 'Fallback',
      iconCode: 0,
      colorValue: 0,
      isCustom: true,
    ));
  });

  setUp(() {
    mockCatRepo = MockCategoryRepository();
    viewModel = CategoryViewModel(mockCatRepo);
  });

  group('CategoryViewModel Tests', () {
    
    group('Data Delegation & Synchronous Feeds', () {
      test('categoriesStream should forward transparently from repository collections', () {
        final combinedList = [...samplePredefinedCategories, ...sampleCustomCategories];
        when(() => mockCatRepo.allCategoriesStream).thenAnswer((_) => Stream.value(combinedList));

        expect(viewModel.categoriesStream, emits(combinedList));
      });

      test('customCategoriesOnly should pipe restricted streams out of the repository layer', () {
        when(() => mockCatRepo.customCategoriesOnlyStream).thenAnswer((_) => Stream.value(sampleCustomCategories));

        expect(viewModel.customCategoriesOnly, emits(sampleCustomCategories));
      });

      test('predefinedCategories getter should pull directly from cache arrays synchronously', () {
        when(() => mockCatRepo.predefinedCategories).thenReturn(samplePredefinedCategories);

        expect(viewModel.predefinedCategories, samplePredefinedCategories);
        verify(() => mockCatRepo.predefinedCategories).called(1);
      });
    });

    group('saveCategory Actions Flow', () {
      test('should force isCustom to true and trigger addCategory when id param is omitted', () async {
        // Arrange
        when(() => mockCatRepo.addCategory(any())).thenAnswer((_) => Future.value());

        int busyNotificationCounter = 0;
        viewModel.addListener(() => busyNotificationCounter++);

        // Act
        final saveFuture = viewModel.saveCategory(
          name: '  Gym Membership ', // Verifying string trimming occurs natively
          iconCode: 555,
          colorValue: 999,
        );

        // Verify intermediate loading/busy flags toggle on immediately
        expect(viewModel.isBusy, true);
        expect(viewModel.errorMessage, null);

        await saveFuture;

        // Assert
        expect(viewModel.isBusy, false);
        expect(busyNotificationCounter, 2); // Fired twice via _setBusy (true, then false)

        verify(() => mockCatRepo.addCategory(any(that: isA<Category>()
          .having((c) => c.id, 'id fallback empty string', '')
          .having((c) => c.name, 'trimmed text title', 'Gym Membership')
          .having((c) => c.isCustom, 'automatically flag as a custom category item', true)
          .having((c) => c.iconCode, 'icon validation matching', 555)
        ))).called(1);
        
        verifyNever(() => mockCatRepo.updateCategory(any()));
      });

      test('should direct payload objects to updateCategory when a valid id target is provided', () async {
        // Arrange
        when(() => mockCatRepo.updateCategory(any())).thenAnswer((_) => Future.value());

        // Act
        await viewModel.saveCategory(
          id: 'cat_custom_1',
          name: 'Gaming',
          iconCode: 777,
          colorValue: 888,
        );

        // Assert
        verify(() => mockCatRepo.updateCategory(any(that: isA<Category>()
          .having((c) => c.id, 'maintains its matching existing document id ID', 'cat_custom_1')
          .having((c) => c.name, 'name string text modification check', 'Gaming')
          .having((c) => c.isCustom, 'remains marked true for custom tracking fields', true)
        ))).called(1);

        verifyNever(() => mockCatRepo.addCategory(any()));
      });

      test('should intercept execution exceptions and surface a tailored validation error message string', () async {
        // Arrange
        when(() => mockCatRepo.addCategory(any())).thenThrow(Exception('Firestore write penalty mismatch'));

        // Act
        await viewModel.saveCategory(
          name: 'Error Trigger',
          iconCode: 0,
          colorValue: 0,
        );

        // Assert
        expect(viewModel.isBusy, false); // Insures finally blocks reset visual flags safely
        expect(viewModel.errorMessage, equals("Failed to save category. Please try again."));
      });
    });
  });
}