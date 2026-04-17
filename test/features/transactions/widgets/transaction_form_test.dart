import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/features/transactions/widgets/transaction_form.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:provider/provider.dart';


class MockTransactionViewModel extends Mock implements TransactionViewModel {}
class MockLanguageProvider extends Mock implements LanguageProvider {}
class MockCurrencyProvider extends Mock implements CurrencyProvider {}
class MockCurrencyFormatter extends Mock implements CurrencyFormatter {}
class MockCurrency extends Mock implements Currency {}

void main() {
  late MockTransactionViewModel mockVM;
  late MockLanguageProvider mockLang;
  late MockCurrencyProvider mockCurrencyProvider;
  late MockCurrencyFormatter mockFormatter;
  late MockCurrency mockCurrency;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    mockVM = MockTransactionViewModel();
    mockLang = MockLanguageProvider();
    mockCurrencyProvider = MockCurrencyProvider();
    mockFormatter = MockCurrencyFormatter();
    mockCurrency = MockCurrency();

    // Setup default mock behaviors
    when(() => mockVM.categories).thenReturn([]);
    when(() => mockVM.isSaving).thenReturn(false);

    when(() => mockLang.localeCode).thenReturn('en');
    when(() => mockLang.translate(any())).thenAnswer((inv) => inv.positionalArguments[0]);

    when(() => mockCurrencyProvider.formatter).thenReturn(mockFormatter);
    when(() => mockCurrencyProvider.currency).thenReturn(mockCurrency);
    when(() => mockCurrency.symbol).thenReturn('Ksh');

    when(() => mockFormatter.formatNumber(any(), any()))
        .thenAnswer((inv) => (inv.positionalArguments[0] as double).toStringAsFixed(2));
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TransactionViewModel>.value(value: mockVM),
        ChangeNotifierProvider<LanguageProvider>.value(value: mockLang),
        ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            FinancialColors(income: Colors.green, expense: Colors.red),
          ],
        ),
        home: Scaffold(
          body: TransactionForm(),
        ),
      ),
    );
  }

  group('TransactionForm Widget Tests -', () {
    
    testWidgets('should display validation errors when fields are empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap the save button
      final saveBtn = find.byType(ElevatedButton);
      await tester.tap(saveBtn);
      await tester.pump(); 

      // Check for error text (assuming translate returns the key as we mocked above)
      expect(find.text('err_amount_empty'), findsOneWidget);
      expect(find.text('err_title_empty'), findsOneWidget);
    });

    testWidgets('should call saveTransaction on ViewModel when form is valid', (tester) async {
      // Arrange
      when(() => mockVM.categories).thenReturn([Category(id: '1', name: 'Food')]);
      when(() => mockVM.saveTransaction(
        title: any(named: 'title'),
        amount: any(named: 'amount'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        date: any(named: 'date'),
      )).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidgetUnderTest());

      // Act: Fill the form
      await tester.enterText(find.byType(TextFormField).first, '50.00'); // Amount
      await tester.enterText(find.byType(TextFormField).last, 'Lunch');   // Title
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      verify(() => mockVM.saveTransaction(
        title: 'Lunch',
        amount: 50.0,
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        date: any(named: 'date'),
      )).called(1);
    });
  });
}