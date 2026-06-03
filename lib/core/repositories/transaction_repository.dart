import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_fin/core/firestore/constants/firestore_path.dart';
import 'package:personal_fin/core/firestore/network/query_options.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/core/services/i_firestore_service.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/category_spending.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/transaction.dart';

class TransactionRepository {
  final IFirestoreService _service;
  final FirebaseAuth _auth;
  final CategoryRepository _categoryRepo;
  final ExchangeRateService _exchangeService;
  final CurrencyProvider _currencyProvider;

  final _monthController = BehaviorSubject<DateTime>.seeded(DateTime.now());

  TransactionRepository(this._currencyProvider, {required IFirestoreService service, required FirebaseAuth auth, required CategoryRepository categoryRepo, required ExchangeRateService exchangeService})
      : _service = service,
        _auth = auth,
        _categoryRepo = categoryRepo,
        _exchangeService = exchangeService;

  // The Reactive Master Stream
  Stream<List<Transaction>> get transactionsStream {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value([]);
    
      return _service.streamCollection<Transaction>(
        collectionPath: transactionsCollectionPath,
        builder: (map) => Transaction.fromMap(map),
        orderBy: [OrderByOption('date', descending: true)],
      );
    });
  }

  Stream<List<Transaction>> get monthlyTransactionsStream {
    return Rx.combineLatest2(
      _auth.authStateChanges(),
      _monthController.stream,
      (user, date) => _TxParams(user?.uid, date),
    ).switchMap((params) {
      if (params.uid == null) return Stream.value([]);

      final start = DateTime(params.date.year, params.date.month, 1);
      final end = DateTime(params.date.year, params.date.month + 1, 0, 23, 59, 59);

      return _service.streamCollection<Transaction>(
        collectionPath: transactionsCollectionPath,
        builder: (map) => Transaction.fromMap(map),
        filters: [
          FieldFilter('date', FilterOperator.isGreaterThanOrEqualTo, start),
          FieldFilter('date', FilterOperator.isLessThanOrEqualTo, end),
        ],
        orderBy: [OrderByOption('date', descending: true)],
      );
    });
  }

  // In TransactionRepository or a new AnalyticsService
  Stream<List<CategorySpending>> getMonthlySpendingStream(DateTime month, String currencyCode) {
    return Rx.combineLatest3(
     monthlyTransactionsStream,
      _categoryRepo.allCategoriesStream,
      _currencyProvider.currencyStream, 
      (transactions, categories, code) {
        final Map<String, double> totals = {};
        final Map<String, Category> categoryMap = {};
        double totalMonthlyExpense = 0.0;

        for (var t in transactions.where((t) => t.type == 'Expense')) {
          final category = categories.firstWhere(
            (c) => c.id == t.categoryId, 
            orElse: () => Category(id: 'unknown', name: 'Other'),
          );
          
          final amount = _exchangeService.fromBase(t.baseAmount, code);
          totalMonthlyExpense += amount;
          totals.update(category.id, (v) => v + amount, ifAbsent: () => amount);
          categoryMap[category.id] = category;
        }

        // Convert map to sorted List<CategorySpending>
        return totals.entries.map((e) {
          final cat = categoryMap[e.key]!;

          final percentage = totalMonthlyExpense > 0 ? (e.value / totalMonthlyExpense) : 0.0;
          return CategorySpending(
            category: cat,
            totalAmount: e.value,
            percentage: percentage,
          );
        }).toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      },
    );
  }

  

  void setMonth(DateTime date) => _monthController.add(date);

  String get currentUid => _auth.currentUser?.uid ?? '';
  String get transactionsCollectionPath => FirestorePath.transactions(currentUid);

  Future<void> addTransaction(Transaction tx) async {
    final uid = currentUid;
    if (uid.isEmpty) throw Exception("Unauthorized");
    await _service.addDocument(collectionPath: transactionsCollectionPath, data: tx.toFirestore());
  }

  Future<void> updateTransaction(Transaction tx) async {
    if (tx.id.isEmpty) throw Exception("ID Required");
    await _service.updateDocument(collectionPath: transactionsCollectionPath, documentId: tx.id, data: tx.toFirestore());
  }

  Future<void> deleteTransaction(String id) async {
    await _service.deleteDocument(collectionPath: transactionsCollectionPath, id: id);
  }
}

class _TxParams {
  final String? uid;
  final DateTime date;
  _TxParams(this.uid, this.date);
}