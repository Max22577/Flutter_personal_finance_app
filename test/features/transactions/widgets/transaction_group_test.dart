import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_form.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_group.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_tile.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/category.dart';
import 'package:provider/provider.dart';
import '../../../helpers/test_helpers.dart';

class MockTransactionViewModel extends Mock implements TransactionViewModel {}


void main() {
  late TestDependencyManager deps;
  late MockTransactionViewModel mockVM;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    deps = TestDependencyManager();
    mockVM = MockTransactionViewModel();

    when(() => mockVM.categories).thenReturn([]);
    when(() => mockVM.isSaving).thenReturn(false);
  });


  group('TransactionGroupWidget Tests -', () {
    testWidgets('displays "today" header when date is today', (tester) async {
      await tester.pumpWidget(deps.wrap(
        TransactionGroupWidget(
          date: DateTime.now(),
          transactions: [],
          categories: [
            Category(id: 'cat1', name: 'Food'),
          ],
          onDelete: (_) {},
        ),
      ));

      expect(find.text('today'), findsOneWidget);
    });

    testWidgets('renders the correct number of transaction tiles', (tester) async {
      final transactions = [
        Transaction(id: '1',userId: 'user1', title: 'Coffee', amount: 5.0, categoryId: 'cat1', date: DateTime.now(), type: 'Expense'),
        Transaction(id: '2',userId: 'user1', title: 'Lunch', amount: 15.0, categoryId: 'cat1', date: DateTime.now(), type: 'Expense'),
      ];

      await tester.pumpWidget(deps.wrap(
        TransactionGroupWidget(
          date: DateTime.now(),
          transactions: transactions,
          categories: [
            Category(id: 'cat1', name: 'Food'),
          ],
          onDelete: (_) {},
        ),
      ));

      // We expect 2 tiles
      expect(find.byType(TransactionTile), findsNWidgets(2));
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('calls onDelete callback when a tile is deleted', (tester) async {
      bool deleteCalled = false;
      final transaction = Transaction(
        id: '1',
        userId: 'user1', 
        title: 'Snack', 
        amount: 2.0, 
        categoryId: 'cat1', 
        date: DateTime.now(), 
        type: 'Expense',
      );

      await tester.pumpWidget(deps.wrap(
        TransactionGroupWidget(
          date: DateTime.now(),
          transactions: [transaction],
          categories: [
            Category(id: 'cat1', name: 'Food'),
          ],
          onDelete: (tx) => deleteCalled = true,
        ),
      ));

      // Assuming TransactionTile has a delete button or action
      // For this example, we find the Tile and simulate the onDelete trigger
      final tile = tester.widget<TransactionTile>(find.byType(TransactionTile));
      tile.onDelete(); 

      expect(deleteCalled, isTrue);
    });

    testWidgets('opens edit form bottom sheet on tile edit tap', (tester) async {
      final transaction = Transaction(
        id: '1', 
        userId: 'user1',
        title: 'Dinner', 
        amount: 30.0, 
        categoryId: 'cat1', 
        date: DateTime.now(), 
        type: 'Expense',
      );

      await tester.pumpWidget(deps.wrap(
        TransactionGroupWidget(
          date: DateTime.now(),
          transactions: [transaction],
          categories: [
            Category(id: 'cat1', name: 'Food'),
          ],
          onDelete: (_) {},
        ),
        extraProviders: [
          ChangeNotifierProvider<TransactionViewModel>.value(value: mockVM),
        ],
      ));

      // Simulate the edit tap
      final tile = tester.widget<TransactionTile>(find.byType(TransactionTile));
      tile.onEdit();
      
      // pumpAndSettle to wait for the BottomSheet animation
      await tester.pumpAndSettle();

      // Check if the form is now visible
      expect(find.byType(TransactionForm), findsOneWidget);
    });
  });
}