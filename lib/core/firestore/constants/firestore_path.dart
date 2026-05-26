import 'package:flutter/foundation.dart';

class FirestorePath {
  static String get appId => (kDebugMode && !kIsWeb) 
      ? 'debug-app-id' 
      : String.fromEnvironment('APP_ID');

  // Root path helper
  static String _root() => 'artifacts/$appId';

  // Specific Collection Paths
  static String savingsGoals(String uid) => '${_root()}/users/$uid/savings_goals';
  static String transactions(String uid) => '${_root()}/users/$uid/transactions';
  static String categories(String uid) => '${_root()}/users/$uid/transaction_categories';
  static String budgets(String uid) => '${_root()}/users/$uid/budgets';
  static String exchangeRates() => '${_root()}/rates';
  
  // Example for nested data
  static String goal(String uid, String goalId) => '${savingsGoals(uid)}/$goalId';
}