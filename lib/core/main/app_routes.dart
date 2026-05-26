import 'package:flutter/material.dart';
import 'package:personal_fin/features/auth/pages/sign_in_page.dart';
import 'package:personal_fin/features/auth/pages/sign_up_page.dart';
import 'package:personal_fin/features/category/views/category_management_page.dart';
import 'package:personal_fin/features/home/views/home_page.dart';
import 'package:personal_fin/features/settings/views/pages/settings_page.dart';
import 'package:personal_fin/features/savings/views/pages/savings_page.dart';
import 'package:personal_fin/features/savings/views/pages/set_goal_page.dart';
import 'package:personal_fin/features/budgeting/views/budgeting_page.dart';
import 'package:personal_fin/features/transactions/views/pages/transactions.dart';
import 'package:personal_fin/features/dashboard/views/pages/dashboard_page.dart';
import 'package:personal_fin/features/dashboard/views/pages/monthly_review_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    '/login': (context) => SignInPage(),
    '/signup': (context) => SignUpPage(),
    '/home': (context) => const HomePage(),
    '/categories': (context) => const CategoryManagementPage(),
    '/settings': (context) => const SettingsPage(),
    '/savings': (context) => const SavingsPage(),
    '/savings/goal': (context) => const SetGoalPage(),
    '/budgeting': (context) => const BudgetingPage(),
    '/transactions': (context) => const TransactionsPage(),
    '/dashboard': (context) => const DashboardPage(),
    '/monthly_review': (context) => const MonthlyReviewPage(),
  };
}