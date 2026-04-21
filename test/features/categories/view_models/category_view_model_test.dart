import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/features/category/view_models/category_view_model.dart';
import 'package:personal_fin/models/category.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late CategoryViewModel viewModel;
  late MockCategoryRepository mockCatRepo;

  setUp(() {
    mockCatRepo = MockCategoryRepository();
    when(() => mockCatRepo.predefinedCategories).thenReturn([
      Category(id: 'c1', name: 'Food'),
      Category(id: 'c2', name: 'Transport'),
    ]);
    when(() => mockCatRepo.customCategoriesStream).thenAnswer((_) => Stream.empty());
    viewModel = CategoryViewModel(mockCatRepo);
  });

  group('General State', () {
    test('Initial state is correct', () {
      expect(viewModel.isBusy, false);
      expect(viewModel.hasError, false);
      expect(viewModel.errorMessage, null);
    });
  });

  group('Category Mutations -', () {
    const String tName = 'Gym';
    const int tIcon = 58115; // Icons.fitness_center.codePoint
    final int tColor = Colors.blue.toARGB32();

    test('addCategory sets busy state and calls repository', () async {
      // ARRANGE
      when(() => mockCatRepo.addCategory(
        name: any(named: 'name'),
        iconCode: any(named: 'iconCode'),
        colorValue: any(named: 'colorValue'),
        isCustom: any(named: 'isCustom'),
      )).thenAnswer((_) async => Future.delayed(const Duration(milliseconds: 50)));

      // ACT
      final future = viewModel.addCategory(
        name: tName,
        iconCode: tIcon,
        colorValue: tColor,
        isCustom: true,

      );

      // ASSERT: Check that it's busy while the future is running
      expect(viewModel.isBusy, true);
      
      await future;

      expect(viewModel.isBusy, false);
      verify(() => mockCatRepo.addCategory(
        name: tName,
        iconCode: tIcon,
        colorValue: tColor,
        isCustom: true,
      )).called(1);
    });

    test('updateCategory handles errors gracefully', () async {
      // ARRANGE
      const errorMsg = 'Please try again';
      when(() => mockCatRepo.updateCategory(
        id: any(named: 'id'),
        name: any(named: 'name'),
        iconCode: any(named: 'iconCode'),
        colorValue: any(named: 'colorValue'),
      )).thenThrow(errorMsg);

      // ACT
      await viewModel.updateCategory(id: 'c1', name: 'New Food');

      // ASSERT
      expect(viewModel.isBusy, false);
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, contains(errorMsg));
    });
  });

  group('Refresh Logic -', () {
    test('refreshCategories calls repository refresh', () async {
      // ARRANGE
      when(() => mockCatRepo.refresh()).thenAnswer((_) async => {});

      // ACT
      await viewModel.refreshCategories();

      // ASSERT
      verify(() => mockCatRepo.refresh()).called(1);
    });
  });

}