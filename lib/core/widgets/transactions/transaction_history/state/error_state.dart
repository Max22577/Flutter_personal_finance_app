import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/pages/transactions.dart';
import 'package:provider/provider.dart';

class ErrorState extends StatelessWidget {
  final String message;
  
  const ErrorState({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              langProvider.translate('failed_to_load_transactions'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // This would need to be passed via callback
                // For now, just refresh the page
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => TransactionsPage(isActive: true),
                  ),
                );
              },
              child: Text(langProvider.translate('try_again')),
            ),
          ],
        ),
      ),
    );
  }
}