import 'package:flutter/material.dart';
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

  group('Mutations -', () {
  const String tId = 'cat_123';
  const String tName = 'Gym';
  const int tIcon = 0xe243; // Icons.fitness_center
  final int tColor = Colors.blue.toARGB32();

  test('addCategory calls service with correct icon and color values', () async {
    // ARRANGE
    when(() => mockFirestoreService.addCategory(
          name: any(named: 'name'),
          iconCode: any(named: 'iconCode'),
          colorValue: any(named: 'colorValue'),
          isCustom: any(named: 'isCustom'),
        )).thenAnswer((_) async => {});

    // ACT
    await repository.addCategory(
      name: tName,
      iconCode: tIcon,
      colorValue: tColor,
      isCustom: true

    );

    // ASSERT
    verify(() => mockFirestoreService.addCategory(
          name: tName,
          iconCode: tIcon,
          colorValue: tColor,
          isCustom: true,
        )).called(1);
  });

  test('updateCategory calls service with provided optional values', () async {
    // ARRANGE
    when(() => mockFirestoreService.updateCategoryName(
          categoryId: any(named: 'categoryId'),
          newName: any(named: 'newName'),
          iconCode: any(named: 'iconCode'),
          colorValue: any(named: 'colorValue'),
        )).thenAnswer((_) async => {});

    // ACT
    await repository.updateCategory(
      id: tId,
      name: 'New Name',
      iconCode: tIcon,
    );

    // ASSERT
    // Note: colorValue was not passed in ACT, so it should be null here
    verify(() => mockFirestoreService.updateCategoryName(
          categoryId: tId,
          newName: 'New Name',
          iconCode: tIcon,
          colorValue: null, 
        )).called(1);
  });
});

group('Error Handling & Lifecycle -', () {
  test('refresh re-initializes streams and waits for first data', () async {
    // ARRANGE
    categoryStreamSubject.add([Category(id: '1', name: 'A')]);
    userCategoryStreamSubject.add([Category(id: '2', name: 'B')]);

    // ACT & ASSERT
    // If it doesn't timeout, the refresh was successful
    await expectLater(repository.refresh(), completes);
    
    // Initial call was in setUp, refresh calls it again
    verify(() => mockFirestoreService.streamCategories()).called(2);
  });
});

  
}
