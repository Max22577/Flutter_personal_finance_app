import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/providers/rate_sync_provider.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/repositories/savings_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/core/services/savings_service.dart';
import 'package:personal_fin/features/auth/view_models/sign_in_view_model.dart';
import 'package:personal_fin/features/budgeting/view_models/budgeting_view_model.dart';
import 'package:personal_fin/features/category/view_models/category_view_model.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/features/home/view_models/home_view_model.dart';
import 'package:personal_fin/features/savings/view_models/savings_view_model.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    // Services
    Provider<IFirestoreService>(create: (_) => FirestoreService()),
    ChangeNotifierProvider(
      create: (context) => ExchangeRateService()
    ),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => NavigationProvider()),
    ChangeNotifierProvider(create: (_) => CurrencyProvider()),
    ChangeNotifierProvider(create: (_) => LanguageProvider()),

    // Repositories 
    ProxyProvider<IFirestoreService, TransactionRepository>(
      update: (_, service, _) => TransactionRepository(
        service: service, 
        auth: FirebaseAuth.instance
      ),
    ),
    ProxyProvider<IFirestoreService, BudgetRepository>(
      update: (_, service, _) => BudgetRepository(service: service, auth: FirebaseAuth.instance),
    ),
    ProxyProvider<IFirestoreService, CategoryRepository>(
      update: (_, service, _) => CategoryRepository(service: service, auth: FirebaseAuth.instance),
    ),
    ProxyProvider4<CategoryRepository, ExchangeRateService, CurrencyProvider, IFirestoreService, MonthlyDataRepository>(
      update: (_, catRepo, exchangeService, currencyProvider, service, _) => MonthlyDataRepository(
        catRepo,
        exchangeService,
        currencyProvider,
        service: service,
        auth: FirebaseAuth.instance,
      ),
    ),
     ProxyProvider3<TransactionRepository, IFirestoreService, ExchangeRateService, SavingsRepository>(
      update: (_, txRepo, service, exchangeService, _) => SavingsRepository(
        txRepo,
        service: service,
        exchangeService: exchangeService,
        auth: FirebaseAuth.instance, 
      ),
    ),
    ProxyProvider3<TransactionRepository, SavingsRepository, IFirestoreService, SavingsService>(
      update: (_, txRepo, savingsRepo, firestoreService, _) => SavingsService(
        transactionRepo: txRepo,
        savingsRepo: savingsRepo,
        firestoreService: firestoreService,
      ),
    ),
        
    // ViewModels (ChangeNotifierProviders)
    ChangeNotifierProvider(create: (context) => HomeViewModel()),
    ChangeNotifierProvider(
      create: (context) => RateSyncProvider(
        exchangeRateService: context.read<ExchangeRateService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => SignInViewModel() 
    ),
    ChangeNotifierProvider(
      create: (context) => DashboardViewModel(
        context.read<MonthlyDataRepository>(), 
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => TransactionViewModel(
        context.read<TransactionRepository>(),
        context.read<CategoryRepository>(),
        context.read<CurrencyProvider>(),
        exchangeService: context.read<ExchangeRateService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => CategoryViewModel(
        context.read<CategoryRepository>()
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => BudgetingViewModel(
        context.read<BudgetRepository>(),
        context.read<TransactionRepository>(),
        context.read<CategoryRepository>(),
        exchangeService: context.read<ExchangeRateService>(),
        currencyStream: context.read<CurrencyProvider>().currencyStream,
      )
    ),
    ChangeNotifierProvider(
      create: (context) => SavingsViewModel(
        context.read<SavingsRepository>(),
        context.read<ExchangeRateService>(),
        context.read<CurrencyProvider>(),
      )
    ),
  ];
}