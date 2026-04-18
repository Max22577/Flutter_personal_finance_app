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

  group('Retry Logic', () {
    test('handles addCategory failure and retries successfully', () async {
      when(() => mockCatRepo.addCategory(any()))
          .thenThrow(Exception('Network Error'));

      await viewModel.addCategory('Coffee');

      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, contains('Failed to add category'));
      verify(() => mockCatRepo.addCategory('Coffee')).called(1);

      when(() => mockCatRepo.addCategory(any())).thenAnswer((_) async => {});

      final retryFuture = viewModel.retryLastAction();
      
      expect(viewModel.isBusy, true);
      expect(viewModel.hasError, false);

      await retryFuture;

      expect(viewModel.isBusy, false);
      expect(viewModel.hasError, false);
      verify(() => mockCatRepo.addCategory('Coffee')).called(1); 
    });

    test('updateCategory captures arguments correctly for retry', () async {
      when(() => mockCatRepo.updateCategory(any(), any()))
          .thenThrow(Exception('Update Failed'));

      await viewModel.updateCategory('c1', 'Dining');

      expect(viewModel.hasError, true);

      when(() => mockCatRepo.updateCategory('c1', 'Dining'))
          .thenAnswer((_) async => {});

      await viewModel.retryLastAction();

      verify(() => mockCatRepo.updateCategory('c1', 'Dining')).called(2);
    });
  });

  group('Busy State Edge Cases', () {
    test('isBusy is false even if repository throws', () async {
      when(() => mockCatRepo.addCategory(any())).thenThrow(Exception('Error'));

      await viewModel.addCategory('Test');

      expect(viewModel.isBusy, false);
      expect(viewModel.hasError, true);
    });
  });

}