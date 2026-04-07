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

  test('Initial state is correct', () {
    expect(viewModel.isBusy, false);
    expect(viewModel.predefinedCategories.length, 2);
  });

  test('addCategory sets busy state correctly', () async {
    when(() => mockCatRepo.addCategory(any())).thenAnswer((_) async {});
    
    final future = viewModel.addCategory('New Category');
    
    expect(viewModel.isBusy, true);
    
    await future;
    
    expect(viewModel.isBusy, false);
    verify(() => mockCatRepo.addCategory('New Category')).called(1);
  });

  test('updateCategory sets busy state correctly', () async {
    when(() => mockCatRepo.updateCategory(any(), any())).thenAnswer((_) async {});
    
    final future = viewModel.updateCategory('c1', 'Updated Name');
    
    expect(viewModel.isBusy, true);
    
    await future;
    
    expect(viewModel.isBusy, false);
    verify(() => mockCatRepo.updateCategory('c1', 'Updated Name')).called(1);
  });
}