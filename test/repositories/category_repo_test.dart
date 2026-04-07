import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/category.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late CategoryRepository repository;
  late MockFirestoreService mockFirestoreService;
  late BehaviorSubject<List<Category>> categoryStreamSubject;
  late BehaviorSubject<List<Category>> userCategoryStreamSubject;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    categoryStreamSubject = BehaviorSubject<List<Category>>();
    userCategoryStreamSubject = BehaviorSubject<List<Category>>();
    
    when(() => mockFirestoreService.streamCategories())
        .thenAnswer((_) => categoryStreamSubject.stream);
    when(() => mockFirestoreService.streamCustomCategories())
        .thenAnswer((_) => userCategoryStreamSubject.stream);

    repository = CategoryRepository(service: mockFirestoreService);
  });

  tearDown(() {
    categoryStreamSubject.close();
    userCategoryStreamSubject.close();
    repository.dispose();
  });

  group('Stream Updates -', () {
    final dummyDefinedCategories = [Category(id: 'c1', name: 'Food')];
    final dummyCustomCategories = [Category(id: 'u1', name: 'Shopping')];

    test('categoriesStream pipes data correctly from Firestore', () async {
      // ACT
      categoryStreamSubject.add(dummyDefinedCategories);
      await Future.delayed(Duration.zero); 

      // ASSERT
      final result = await repository.categoriesStream.first;
      expect(result, dummyDefinedCategories);
      expect(result.first.name, 'Food');
      verify(() => mockFirestoreService.streamCategories()).called(1);
    });

    test('customCategoriesStream pipes data correctly from Firestore', () async {
      // ACT
      userCategoryStreamSubject.add(dummyCustomCategories);
      await Future.delayed(Duration.zero);

      // ASSERT
      final result = await repository.customCategoriesStream.first;
      expect(result, dummyCustomCategories);
      expect(result.first.name, 'Shopping');
      verify(() => mockFirestoreService.streamCustomCategories()).called(1);
    });
  });

  group('Getters -', () {
    test('predefinedCategories returns service data', () {
      // ARRANGE
      final dummyPredefined = [Category(id: 'p1', name: 'Bills')];
      when(() => mockFirestoreService.predefinedCategories).thenReturn(dummyPredefined);

      // ACT & ASSERT
      expect(repository.predefinedCategories, dummyPredefined);
      verify(() => mockFirestoreService.predefinedCategories).called(1);
    });
  });

  group('Actions -', () {
    test('addCategory calls Firestore service with correct name', () async {
      // ARRANGE
      const newCategoryName = 'Gym';
      when(() => mockFirestoreService.addCategory(newCategoryName))
          .thenAnswer((_) async => Future.value());

      // ACT
      await repository.addCategory(newCategoryName);

      // ASSERT
      verify(() => mockFirestoreService.addCategory(newCategoryName)).called(1);
    });

    test('updateCategory calls Firestore service with correct ID and name', () async {
      // ARRANGE
      const catId = 'u1';
      const newName = 'Groceries';
      when(() => mockFirestoreService.updateCategoryName(catId, newName))
          .thenAnswer((_) async => Future.value());

      // ACT
      await repository.updateCategory(catId, newName);

      // ASSERT
      verify(() => mockFirestoreService.updateCategoryName(catId, newName)).called(1);
    });
  });
}
