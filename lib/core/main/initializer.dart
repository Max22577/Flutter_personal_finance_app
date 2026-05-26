import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/providers/theme_provider.dart';
import 'package:personal_fin/core/services/preferences.dart';
import 'package:personal_fin/main.dart';
import 'package:provider/provider.dart';

class InitializerWidget extends StatefulWidget {
  const InitializerWidget({super.key});

  @override
  State<InitializerWidget> createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    final theme = context.read<ThemeProvider>();
    final currency = context.read<CurrencyProvider>();
    final lang = context.read<LanguageProvider>();

    PreferencesService();

    await Future.wait([
      theme.initialize(),
      currency.init(),
      lang.init(),
    ]);

    if (mounted) setState(() => _isReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return const MyApp();
  }
}