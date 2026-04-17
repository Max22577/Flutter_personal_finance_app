import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:personal_fin/core/utils/currency_formatter.dart';
import 'package:personal_fin/models/currency.dart';
import 'package:provider/provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:provider/single_child_widget.dart';

// --- Global Mock Definitions ---
class MockLanguageProvider extends Mock implements LanguageProvider {}
class MockThemeProvider extends Mock implements ThemeProvider {}
class MockCurrencyProvider extends Mock implements CurrencyProvider {}
class MockCurrencyFormatter extends Mock implements CurrencyFormatter {}
class MockCurrency extends Mock implements Currency {}


class TestDependencyManager {
  final mockLang = MockLanguageProvider();
  final mockCurrencyProvider = MockCurrencyProvider();
  final mockFormatter = MockCurrencyFormatter();
  final mockCurrency = MockCurrency();
  final mockThemeProvider = MockThemeProvider();

  TestDependencyManager() {
    registerFallbackValue(MockCurrency());

    // Default stubs for Language
    when(() => mockLang.localeCode).thenReturn('en');
    when(() => mockLang.translate(any())).thenAnswer((inv) {    
      return inv.positionalArguments[0] as String;   
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
  }

  Widget wrap(
    Widget child, 
    {List<SingleChildWidget>? extraProviders,
    ThemeMode themeMode = ThemeMode.light}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: mockLang),
        ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        if (extraProviders != null) ...extraProviders,
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          extensions: [
            FinancialColors(income: Colors.green, expense: Colors.red),
          ],
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark, // 👈 Explicit dark theme
          extensions: [
            FinancialColors(income: Colors.green, expense: Colors.red),
          ],
        ),
        themeMode: themeMode,
        home: Scaffold(body: child),
      ),
    );
  }
}