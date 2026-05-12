import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:rxdart/rxdart.dart';

class BudgetRepository {
  final FirestoreService _service;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _appId = (kDebugMode && !kIsWeb) ? 'debug-app-id' : String.fromEnvironment('APP_ID');
  
  // A controller to handle month switching reactively
  final _monthYearController = BehaviorSubject<String>();

  BudgetRepository({FirestoreService? service})
      : _service = service ?? FirestoreService.instance;

  CollectionReference _budgetRef(String uid) =>
      FirebaseFirestore.instance.collection('artifacts/$_appId/users/$uid/budgets');

  // TRIGGER: Call this when the user changes the date in the UI
  void updateMonthYear(String monthYear) => _monthYearController.add(monthYear);

  // REACTIVE STREAM
  Stream<List<Budget>> get budgetsStream {
    return Rx.combineLatest2(
      _auth.authStateChanges(),
      _monthYearController.stream,
      (user, monthYear) => _MonthUser(user?.uid, monthYear),
    ).switchMap((data) {
      if (data.uid == null) return Stream.value([]);
      
      final query = _budgetRef(data.uid!).where('monthYear', isEqualTo: data.monthYear);
      return _service.streamCollection<Budget>(
        query: query,
        builder: (doc) => Budget.fromFirestore(doc),
      );
    });
  }

  Future<void> setBudget(Budget budget) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Unauthorized");
    
    // Consistent ID: CategoryId + MonthYear
    final docId = '${budget.categoryId}_${budget.monthYear}';
    await _service.saveBudget(_budgetRef(uid).doc(docId), budget.toJson());
  }
  String get uid => _auth.currentUser?.uid ?? '';
}

class _MonthUser {
  final String? uid;
  final String monthYear;
  _MonthUser(this.uid, this.monthYear);
}