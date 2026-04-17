import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/features/dashboard/pages/dashboard_page.dart';
import 'package:personal_fin/features/dashboard/pages/monthly_review_page.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/features/dashboard/widgets/monthly_review.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MockDashboardViewModel extends Mock implements DashboardViewModel {}
class MockLanguageProvider extends Mock implements LanguageProvider {}
class MockCurrencyProvider extends Mock implements CurrencyProvider {}
class MockCurrencyFormatter extends Mock implements CurrencyFormatter {}
class MockCurrency extends Mock implements Currency {}
class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockMonthlyDataRepository extends Mock implements MonthlyDataRepository {}
class MockMonthlyTransactionRepository extends Mock implements MonthlyTransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockDashboardViewModel mockVM;
  late MockLanguageProvider mockLang;
  late MockCurrencyProvider mockCurrencyProvider;
  late MockCurrencyFormatter mockFormatter;
  late MockCurrency mockCurrency;
  late MockTransactionRepository mockTransRepo;
  late MockMonthlyDataRepository mockMonthlyRepo;
  late MockMonthlyTransactionRepository mockTxRepo;
  late MockCategoryRepository mockCatRepo;
  late MockNavigatorObserver mockNav;

  late BehaviorSubject<List<Transaction>> transactionsSubject;
  late BehaviorSubject<List<Transaction>> transactionsDataSubject;
  late BehaviorSubject<List<Category>> categoriesSubject;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockVM = MockDashboardViewModel();
    mockLang = MockLanguageProvider();
    mockCurrencyProvider = MockCurrencyProvider();
    mockFormatter = MockCurrencyFormatter();
    mockCurrency = MockCurrency();
    mockTransRepo = MockTransactionRepository();
    mockMonthlyRepo = MockMonthlyDataRepository();
    mockTxRepo = MockMonthlyTransactionRepository();
    mockCatRepo = MockCategoryRepository();
    mockNav = MockNavigatorObserver();

    transactionsSubject = BehaviorSubject<List<Transaction>>();
    categoriesSubject = BehaviorSubject<List<Category>>();
    transactionsDataSubject = BehaviorSubject<List<Transaction>>();

    // Stub the streams FIRST
    when(() => mockTxRepo.stream).thenAnswer((_) => transactionsSubject.stream);
    when(() => mockCatRepo.categoriesStream).thenAnswer((_) => categoriesSubject.stream);
    when(() => mockTransRepo.transactionsStream).thenAnswer((_) => transactionsDataSubject.stream);

    // Default Passthrough for translations
    when(() => mockLang.localeCode).thenReturn('en');
    when(() => mockLang.translate(any())).thenAnswer((inv) => inv.positionalArguments[0] as String);
    when(() => mockLang.localeStream).thenAnswer((_) => Stream.value('en'));

    when(() => mockCurrencyProvider.currency).thenReturn(mockCurrency);
    when(() => mockCurrency.symbol).thenReturn('Ksh');
    when(() => mockCurrencyProvider.formatter).thenReturn(mockFormatter);

    when(() => mockFormatter.formatNumber(any(), any()))
        .thenAnswer((inv) => (inv.positionalArguments[0] as double).toStringAsFixed(2));
    when(() => mockFormatter.formatDisplay(any(), any()))
        .thenAnswer((inv) => (inv.positionalArguments[0] as double).toStringAsFixed(2));
    when(() => mockFormatter.formatCompact(any(), any()))
        .thenAnswer((inv) => '${(inv.positionalArguments[0] as double).toInt()}K');
    
    // Default repository mock behavior
    when(() => mockTransRepo.refresh()).thenAnswer((_) async {});
    when(() => mockMonthlyRepo.refresh()).thenAnswer((_) async {});
  });

  tearDown(() {
    transactionsSubject.close();
    categoriesSubject.close();
    transactionsDataSubject.close();
  });

  // Helper to wrap the widget with all necessary providers
  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DashboardViewModel>.value(value: mockVM),
        ChangeNotifierProvider<LanguageProvider>.value(value: mockLang),
        ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
        Provider<TransactionRepository>.value(value: mockTransRepo),
        Provider<MonthlyDataRepository>.value(value: mockMonthlyRepo),
        Provider<MonthlyTransactionRepository>.value(value: mockTxRepo),
        Provider<CategoryRepository>.value(value: mockCatRepo),
      ],      
      child: MaterialApp(
        theme: ThemeData(
        extensions: [
          FinancialColors(income: Colors.green, expense: Colors.red), 
        ],
      ),
        home: const DashboardPage(),
        navigatorObservers: [mockNav],
      ),
    );
  }

  group('DashboardPage UI Tests', () {
    testWidgets('shows loading indicator when viewModel.isLoading is true', (tester) async {
      when(() => mockVM.isLoading).thenReturn(true);
      when(() => mockVM.errorMessage).thenReturn(null);
      

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsNWidgets(4));
    });

    testWidgets('shows error card and calls retry when button pressed', (tester) async {
      when(() => mockVM.isLoading).thenReturn(false);
      when(() => mockVM.errorMessage).thenReturn('Failed to load');
      when(() => mockVM.retry()).thenAnswer((_) async {});
      
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('error_loading_monthly_data'), findsOneWidget);
      
      await tester.tap(find.text('retry'));
      verify(() => mockVM.retry()).called(1);
    });

    testWidgets('renders MonthlyReview and navigates on tap', (tester) async {
      final testMonth = DateTime(2026, 4);
      final dummyCurrent = MonthlyData(month: testMonth, income: 5000, expenses: 3000);
      final dummyPrevious = MonthlyData(month: DateTime(2026, 3), income: 4000, expenses: 2000);

      when(() => mockVM.isLoading).thenReturn(false);
      when(() => mockVM.errorMessage).thenReturn(null);
      when(() => mockVM.currentMonthData).thenReturn(dummyCurrent);
      when(() => mockVM.previousMonthData).thenReturn(dummyPrevious);


      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      final reviewFinder = find.byType(MonthlyReview);

      // Ensure the widget is actually in the viewport before tapping
      await tester.ensureVisible(reviewFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Tap to navigate
      await tester.tap(reviewFinder);
      await tester.pumpAndSettle();
      
      // Verify navigation occurred by checking for MonthlyReviewPage
      expect(find.byType(MonthlyReviewPage), findsOneWidget);
    });

    testWidgets('RefreshIndicator triggers repository refreshes', (tester) async {
      when(() => mockVM.isLoading).thenReturn(false);
      when(() => mockVM.errorMessage).thenReturn(null);
      when(() => mockVM.currentMonthData).thenReturn(MonthlyData(month: DateTime.now(), income: 0, expenses: 0));

      await tester.pumpWidget(createWidgetUnderTest());

      // Simulate a pull-to-refresh gesture
      await tester.fling(find.byKey(const Key('dashboard_main_scroll')), const Offset(0, 300), 1000);
      await tester.pump(); 
      await tester.pump(const Duration(seconds: 1)); 

      verify(() => mockTransRepo.refresh()).called(1);
      verify(() => mockMonthlyRepo.refresh()).called(1);
    });
  });
}