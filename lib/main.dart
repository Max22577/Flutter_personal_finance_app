import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fin/core/main/app_routes.dart';
import 'package:personal_fin/core/main/initializer.dart';
import 'package:personal_fin/core/providers/app_providers.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:personal_fin/core/theme/app_theme.dart'; 
import 'package:personal_fin/features/auth/pages/sign_in_page.dart';
import 'package:personal_fin/features/home/views/home_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  await initializeDateFormatting();

  runApp(
    MultiProvider(
      providers: AppProviders.providers,
      child: const InitializerWidget(), 
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
          routes: AppRoutes.routes,
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