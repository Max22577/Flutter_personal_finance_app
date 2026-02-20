import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/navigation_provider.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';
import 'package:personal_fin/pages/auth/sign_in.dart';
import 'package:personal_fin/pages/category.dart';
import 'package:personal_fin/pages/home.dart';
import 'package:personal_fin/pages/savings/savings.dart';
import 'package:personal_fin/pages/savings/set_savings_goal.dart';
import 'package:personal_fin/pages/settings_page/settings.dart';
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
  
  final themeProvider = ThemeProvider();
  await themeProvider.initialize(); 
  
  final navigationProvider = NavigationProvider();

  final currencyProvider = CurrencyProvider();
  await currencyProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value( 
          value: themeProvider, 
        ),
        ChangeNotifierProvider.value(
          value: navigationProvider, 
        ),
        ChangeNotifierProvider.value(
          value: currencyProvider, 
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOut, 
          darkTheme: AppThemes.darkTheme,    
          themeMode: themeProvider.themeMode,
          routes: {
            '/login': (context) => const SignInPage(),
            '/signup': (context) => const SignInPage(),
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
              return const SignInPage();
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