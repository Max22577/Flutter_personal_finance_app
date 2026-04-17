import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/features/budgeting/view_models/budgeting_view_model.dart';
import 'package:personal_fin/features/home/view_models/home_view_model.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:provider/single_child_widget.dart';

class MockLanguageProvider extends Mock implements LanguageProvider {}
class MockNavigationProvider extends Mock with ChangeNotifier implements NavigationProvider {}
class MockThemeProvider extends Mock implements ThemeProvider {}
class MockTransactionViewModel extends Mock implements TransactionViewModel {}
class MockCurrencyProvider extends Mock implements CurrencyProvider {}
class MockCurrencyFormatter extends Mock implements CurrencyFormatter {}
class MockCurrency extends Mock implements Currency {}
class MockHomeViewModel extends Mock implements HomeViewModel {}
class MockBudgetingViewModel extends Mock implements BudgetingViewModel {}
class MockProfileViewModel extends Mock implements ProfileViewModel {}

class TestNavigationDependencyManager {
  late MockNavigationProvider mockNav;
  late MockLanguageProvider mockLang;
  late MockTransactionViewModel mockTransactionVM;
  late MockCurrencyProvider mockCurrencyProvider;
  late MockThemeProvider mockThemeProvider;
  late MockCurrencyFormatter mockFormatter;
  late MockCurrency mockCurrency;
  late MockHomeViewModel mockHomeVM;
  late MockBudgetingViewModel mockBudgetingVM;
  late MockProfileViewModel mockProfileVM;

  List<Widget>? _forcedCurrentActions;

  TestNavigationDependencyManager() {
    mockNav = MockNavigationProvider();
    mockLang = MockLanguageProvider();
    mockCurrencyProvider = MockCurrencyProvider();
    mockThemeProvider = MockThemeProvider();
    mockFormatter = MockCurrencyFormatter();
    mockCurrency = MockCurrency();
    mockTransactionVM = MockTransactionViewModel();
    mockHomeVM = MockHomeViewModel();
    mockBudgetingVM = MockBudgetingViewModel();
    mockProfileVM = MockProfileViewModel();


    // Default stubs for NavigationProvider    
    when(() => mockNav.selectedIndex).thenReturn(0);
    when(() => mockNav.currentTitle).thenReturn('');
    when(() => mockNav.currentActions).thenAnswer((_) {
      return _forcedCurrentActions ?? [];
    });
    
    // Default stubs for LanguageProvider
    when(() => mockLang.localeCode).thenReturn('en');
    when(() => mockLang.translate(any())).thenAnswer((inv) {    
      return inv.positionalArguments[0] as String;
      // key.replaceAll('_', ' ').toUpperCase();    
    });
    when(() => mockLang.localeStream).thenAnswer((_) => Stream.value('en'));

    // Default stubs for Currency
    when(() => mockCurrencyProvider.formatter).thenReturn(mockFormatter);
    when(() => mockCurrencyProvider.currency).thenReturn(mockCurrency);
    when(() => mockCurrency.symbol).thenReturn('Ksh');

    // Default stubs for Formatting
    when(() => mockFormatter.formatDisplay(any(), any()))
      .thenAnswer((inv) => (inv.positionalArguments[0] as double).toStringAsFixed(2));
    when(() => mockFormatter.formatCompact(any(), any()))
      .thenAnswer((inv) => '${(inv.positionalArguments[0] as double).toInt()}K');
    when(() => mockFormatter.formatNumber(any(), any()))
      .thenAnswer((inv) => (inv.positionalArguments[0] as double).toStringAsFixed(2));

    // Default HomeViewModel stubs
    when(() => mockHomeVM.displayName).thenReturn('Test User');
    when(() => mockHomeVM.email).thenReturn('test@example.com');
    when(() => mockHomeVM.getTabIndex(any())).thenReturn(null);
    when(() => mockHomeVM.getTabIndex('/dashboard')).thenReturn(0);

    when(() => mockTransactionVM.isLoading).thenReturn(false);
    when(() => mockTransactionVM.isSaving).thenReturn(false);
    when(() => mockTransactionVM.errorMessage).thenReturn(null);
    when(() => mockTransactionVM.transactions).thenReturn([]);
    when(() => mockTransactionVM.groupedTransactions).thenReturn({});
    when(() => mockTransactionVM.categories).thenReturn([]);

  }

  void stubNavigation({
    String title = '',
    List<Widget>? actions,
    bool useCapturedActions = false,
  }) {
    when(() => mockNav.currentTitle).thenReturn(title);
    
    if (useCapturedActions) {
      _forcedCurrentActions = null;
    } else if (actions != null) {
      _forcedCurrentActions = actions;
    } else {
      _forcedCurrentActions = [];
    }
    
    mockNav.notifyListeners();
  }

  // Helper for testing setActions() behavior
  void enableActionCapture() {
    _forcedCurrentActions = null;
    mockNav.notifyListeners();
  }

  Widget wrap(Widget child, {List<NavigatorObserver>? observers, List<SingleChildWidget>? extraProviders,}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NavigationProvider>.value(value: mockNav),
        ChangeNotifierProvider<LanguageProvider>.value(value: mockLang),
        ChangeNotifierProvider<HomeViewModel>.value(value: mockHomeVM),
        ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<TransactionViewModel>.value(value: mockTransactionVM),
        ChangeNotifierProvider<BudgetingViewModel>.value(value: mockBudgetingVM),
        ChangeNotifierProvider<ProfileViewModel>.value(value: mockProfileVM),
        if (extraProviders != null) ...extraProviders,
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            FinancialColors(income: Colors.green, expense: Colors.red),
          ],
        ),
        navigatorObservers: observers ?? [],
        home: _TestShell(includeShellAppBar: true, child: child),
      ),
    );
  }
}

class _TestShell extends StatefulWidget {
  final Widget child;
  final bool includeShellAppBar;
  const _TestShell({required this.child, this.includeShellAppBar = false});

  @override
  State<_TestShell> createState() => _TestShellState();
}

class _TestShellState extends State<_TestShell> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: widget.includeShellAppBar 
          ? AppBar(actions: context.watch<NavigationProvider>().currentActions)
          : null,
      body: widget.child,
    );
  }
}