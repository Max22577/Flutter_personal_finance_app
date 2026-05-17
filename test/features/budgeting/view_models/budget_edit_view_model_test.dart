import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/budgeting/view_models/budget_edit_view_model.dart';


// Create a simple mock class for the callback function so mocktail can verify parameters
abstract class SaveCallbackWrapper {
  Future<void> call(String categoryId, double amount, String monthYear);
}
class MockSaveCallback extends Mock implements SaveCallbackWrapper {}

void main() {
  late BudgetEditViewModel viewModel;
  late MockSaveCallback mockOnSave;

  const String tCategoryId = 'cat_entertainment';
  const String tMonthYear = 'May 2026';

  setUp(() {
    mockOnSave = MockSaveCallback();
    viewModel = BudgetEditViewModel(
      onSave: mockOnSave.call,
      categoryId: tCategoryId,
      monthYear: tMonthYear,
    );
  });

  group('BudgetEditViewModel Tests', () {
    
    test('should instantly return false without firing callback if raw input text cannot be parsed to a number', () async {
      // Act
      final result = await viewModel.updateBudget('abc_invalid_amount');

      // Assert
      expect(result, false);
      expect(viewModel.isSaving, false);
      
      // Ensure the database saving engine was completely skipped
      verifyNever(() => mockOnSave.call(any(), any(), any()));
    });

    test('should execute injected onSave callback with correctly parsed double parameters when input is valid', () async {
      // Arrange
      when(() => mockOnSave.call(tCategoryId, 350.75, tMonthYear))
          .thenAnswer((_) => Future.value());

      int notifyListenersCounter = 0;
      viewModel.addListener(() => notifyListenersCounter++);

      // Act
      final saveFuture = viewModel.updateBudget('  350.75  '); // Double padding checking

      // Assert intermediate state toggles instantly on invocation
      expect(viewModel.isSaving, true);

      final result = await saveFuture;

      // Post-execution state checking
      expect(result, true);
      expect(viewModel.isSaving, false);
      expect(notifyListenersCounter, 2); // 1 for starting, 1 for completing

      // Prove that the exact functional parameters were safely forwarded to the handler
      verify(() => mockOnSave.call(tCategoryId, 350.75, tMonthYear)).called(1);
    });

    test('should catch internal callback execution failures and return false gracefully', () async {
      // Arrange - Simulate a server timeout inside the injected callback function
      when(() => mockOnSave.call(any(), any(), any()))
          .thenThrow(Exception('Cloud network transaction rejected'));

      // Act
      final result = await viewModel.updateBudget('100.00');

      // Assert
      expect(result, false);
      expect(viewModel.isSaving, false); // Ensures loading spinner lowers even on fatal crash waves
    });
  });
}