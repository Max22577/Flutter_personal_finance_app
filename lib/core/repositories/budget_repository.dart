import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/firestore/constants/firestore_path.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:rxdart/rxdart.dart';

class BudgetRepository {
  final IFirestoreService _service;
  final FirebaseAuth _auth;
 
  // A controller to handle month switching reactively
  final _monthYearController = BehaviorSubject<String>.seeded('');

  BudgetRepository({required IFirestoreService service, required FirebaseAuth auth})
      : _service = service, _auth = auth;

  String get uid => _auth.currentUser?.uid ?? '';
  String get budgetsCollectionPath => FirestorePath.budgets(uid);

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
      
      return _service.streamCollection<Budget>(
        collectionPath: budgetsCollectionPath,
        builder: (map) => Budget.fromMap(map),
        filters: [FieldFilter('monthYear', FilterOperator.isEqualTo, data.monthYear)],
      );
    });
  }

  Future<void> setBudget(Budget budget) async {
    final uid = _auth.currentUser?.uid;                                                                                                                                                                               
    if (uid == null) throw Exception("Unauthorized");
    
    await _service.setDocument(collectionPath: budgetsCollectionPath, documentId: budget.id, data: budget.toMap());
  } 
}

class _MonthUser {
  final String? uid;
  final String monthYear;
  _MonthUser(this.uid, this.monthYear);
}