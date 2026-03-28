import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:personal_fin/core/repositories/budget_repository.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/features/auth/pages/sign_in_page.dart';
import 'package:personal_fin/features/auth/view_models/sign_in_view_model.dart';
import 'package:personal_fin/features/budgeting/view_models/budgeting_view_model.dart';
import 'package:personal_fin/features/category/pages/category_management_page.dart';
import 'package:personal_fin/features/category/view_models/category_view_model.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/features/savings/pages/savings_page.dart';
import 'package:personal_fin/features/savings/pages/set_goal_page.dart';
import 'package:personal_fin/features/settings/pages/settings_page.dart';
import 'package:personal_fin/features/transactions/view_models/transactions_view_model.dart';
import 'package:personal_fin/features/home/home.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await FirestoreService.initialize();
  await GoogleSignIn.instance.initialize();

  await initializeDateFormatting();
  
  final themeProvider = ThemeProvider();
  await themeProvider.initialize(); 
  
  final navigationProvider = NavigationProvider();

  final currencyProvider = CurrencyProvider();
  await currencyProvider.init();

  final languageProvider = LanguageProvider();
  await languageProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => TransactionRepository()),
        Provider(create: (_) => MonthlyDataRepository()),
        Provider(create: (_) => CategoryRepository()),
        Provider(create: (_) => BudgetRepository()),
        Provider(create: (_) => MonthlyTransactionRepository()),
        ChangeNotifierProvider.value( 
          value: themeProvider, 
        ),
        ChangeNotifierProvider.value(
          value: navigationProvider, 
        ),
        ChangeNotifierProvider.value(
          value: currencyProvider, 
        ),
        ChangeNotifierProvider.value(
          value: languageProvider, 
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
            context.read<MonthlyTransactionRepository>(),
            context.read<CategoryRepository>(),
            context.read<LanguageProvider>(),
          )
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOut, 
          darkTheme: AppThemes.darkTheme,    
          themeMode: themeProvider.themeMode,
          locale: Locale(langProvider.localeCode),
          routes: {
            '/login': (context) => SignInPage(),
            '/signup': (context) => SignInPage(),
            '/home': (context) => const HomePage(),
            '/categories': (context) => const CategoryManagementPage(),
            '/settings': (context) => const SettingsPage(),
            '/savings': (context) => const SavingsPage(),
            '/savings/goal': (context) => const SetGoalPage(),
          },
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen(themeProvider);
              }
              if (snapshot.hasData) {
                return const HomePage();
              }
              return SignInPage();
            },
          ),
        );
      },
    );
  }
  
  Widget _buildLoadingScreen(ThemeProvider themeProvider) {
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: themeProvider.currentTheme.primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: themeProvider.currentTheme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}