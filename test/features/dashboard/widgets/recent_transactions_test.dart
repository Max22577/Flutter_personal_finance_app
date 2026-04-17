import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/features/dashboard/widgets/recent_transactions.dart';
import 'package:personal_fin/features/dashboard/widgets/transaction_item.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../../../helpers/test_helpers.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepo;
  late TestDependencyManager deps; 
  late BehaviorSubject<List<Transaction>> transactionsSubject;

  setUp(() {
    mockRepo = MockTransactionRepository();
    deps = TestDependencyManager(); 
    transactionsSubject = BehaviorSubject<List<Transaction>>();

    when(() => mockRepo.transactionsStream).thenAnswer((_) => transactionsSubject.stream);
    when(() => mockRepo.getCategoryName(any())).thenAnswer((_) async => 'Test Category');
  });

  testWidgets('renders a list of TransactionItem when data is emitted', (tester) async {
    final transactions = [
      Transaction(id: '1', userId: 'u1', title: 'Coffee', amount: 5, date: DateTime.now(), type: 'Expense', categoryId: 'c1'),
      Transaction(id: '2', userId: 'u1', title: 'Salary', amount: 5000, date: DateTime.now(), type: 'Income', categoryId: 'c2'),
    ];

    await tester.pumpWidget(deps.wrap(
      const RecentTransactions(),
      extraProviders: [
        Provider<TransactionRepository>.value(value: mockRepo),
      ],
    ));

    transactionsSubject.add(transactions);
    await tester.pumpAndSettle();

    expect(find.byType(TransactionItem), findsNWidgets(2));
    expect(find.text('Coffee'), findsOneWidget);

    expect(find.text('Ksh 5000.00'), findsOneWidget); 
  });
}