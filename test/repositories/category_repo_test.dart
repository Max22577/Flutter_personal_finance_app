import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/category.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockIFirestoreService extends Mock implements IFirestoreService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late CategoryRepository repository;
  late MockIFirestoreService mockFirestoreService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(OrderByOption('test'));
  });

  setUp(() {
    mockFirestoreService = MockIFirestoreService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('user_456');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
    when(() => mockFirestoreService.streamCollection<Category>(
        collectionPath: any(named: 'collectionPath'),
        builder: any<Category Function(Map<String, dynamic>)>(named: 'builder'),
        orderBy: any(named: 'orderBy'),
      )).thenAnswer((_) => Stream.value([]));

    repository = CategoryRepository(service: mockFirestoreService, auth: mockAuth);
  });

  group('CategoryRepository Tests', () {
    final customCategory = Category(id: 'cat_custom', name: 'Streaming Services');

    group('Cache & Sync Lookup', () {
      test('should return predefined categories by default when looking up predefined ID', () {
        // Act
        final name = repository.getNameByIdSync('cat_food');
        
        // Assert
        expect(name, 'Food');
      });

      test('should return Unknown Category if ID is not found in cache', () {
        // Act
        final name = repository.getNameByIdSync('non_existent_id');
        
        // Assert
        expect(name, 'Unknown Category');
      });
    });

    group('allCategoriesStream', () {
      test('should emit combined predefined and Firestore categories, updating the cache', () async {
        // Arrange
        when(() => mockFirestoreService.streamCollection<Category>(
              collectionPath: any(named: 'collectionPath'),
              builder: any<Category Function(Map<String, dynamic>)>(named: 'builder'),
              orderBy: any(named: 'orderBy'),
            )).thenAnswer((_) => Stream.value([customCategory]));

        // Act & Assert
        // The stream should emit 5 predefined categories + 1 custom category = 6 total
        expect(
          repository.allCategoriesStream,
          emitsThrough(isA<List<Category>>().having((list) => list.length, 'length', 6)),
        );

        // Allow the stream emission microtask to process completely
        await microtaskFlush();

        // Verify the cache side-effect successfully occurred
        expect(repository.getNameByIdSync('cat_custom'), 'Streaming Services');
      });

      test('should only emit predefined categories when unauthenticated', () {
        // Arrange
        when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

        // Act & Assert
        expect(
          repository.allCategoriesStream,
          emits(isA<List<Category>>().having((list) => list.length, 'length', 5)),
        );
      });
    });

    group('Mutations', () {
      test('addCategory should trigger service layer with mapped data', () async {
        // Arrange
        when(() => mockFirestoreService.addDocument(
              collectionPath: any(named: 'collectionPath'),
              data: any(named: 'data'),
            )).thenAnswer((_) => Future.value());

        // Act
        await repository.addCategory(customCategory);

        // Assert
        verify(() => mockFirestoreService.addDocument(
              collectionPath: any(named: 'collectionPath'),
              data: any(named: 'data'),
            )).called(1);
      });

      test('addCategory should throw Exception if user is logged out', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(() => repository.addCategory(customCategory), throwsException);
      });
    });
  });
}

// Small test helper to empty out pending event loop frames
Future<void> microtaskFlush() => Future.delayed(Duration.zero);