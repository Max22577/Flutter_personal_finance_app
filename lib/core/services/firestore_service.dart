import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';
import '../../models/savings.dart';

const String __appId = (kDebugMode && !kIsWeb) ? 'debug-app-id' : String.fromEnvironment('APP_ID');

class FirestoreService {
  FirebaseFirestore? _db;
  FirebaseAuth? _auth;
  String? _appId;
  String? _currentUserId;
  static FirestoreService? _instance;

  final Completer<void> _initializationCompleter = Completer<void>();
  final DateFormat _monthYearFormat = DateFormat('yyyy-MM');
  List<Category> _allCategoriesCache = [];

  static FirestoreService get instance {
    if (_instance == null) {
      throw Exception('FirestoreService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  // Private constructor
  FirestoreService._internal() {
    _initializeFirebase();
  }

  static Future<FirestoreService> initialize() async {
    if (_instance == null) {
      _instance = FirestoreService._internal();
      await _instance!._initializationCompleter.future;
    }
    return _instance!;
  }

  // Helper to await initialization before proceeding with any database calls
  Future<void> get isReady => _initializationCompleter.future;

  // ------------------------------------------
  // 1. Initialization and Authentication (MANDATORY)
  // ------------------------------------------
  Future<void> _initializeFirebase() async {
    try {  
      _db = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _appId = __appId;
         
      debugPrint('FirestoreService initialized. UID: ${_auth!.currentUser?.uid}');
      _auth!.authStateChanges().listen((User? user) {
        _currentUserId = user?.uid;
        if (user != null) {
          debugPrint('User signed in: $_currentUserId');
          initializeCategoryListener(); // Restart listeners for the new user
        } else {
          debugPrint('User signed out');
        }
      });
      _initializationCompleter.complete();
      
    } catch (e) {
      debugPrint('FATAL Firebase initialization error: $e');
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
    }
  }

  void initializeCategoryListener() {
    streamCategories().listen((categories) {
      _allCategoriesCache = categories;
      debugPrint("Category cache updated: ${_allCategoriesCache.length} items");
    });
  }
  // ------------------------------------------
  // 2. Path Resolution (MANDATORY SECURE PATHS)
  // ------------------------------------------

  // Get current user id - throws if not signed in, but initialization handles this.
  Future<String> getUserId() async {
    await isReady;
    // Check the live auth instance, not a cached variable
    final uid = _auth?.currentUser?.uid ?? _currentUserId;
    
    if (uid == null) {
      // Instead of just throwing, wait a moment for the Auth Stream to catch up
      await Future.delayed(const Duration(milliseconds: 500));
      final retryUid = _auth?.currentUser?.uid;
      if (retryUid == null) {
        throw Exception('No user logged in. Firestore paths cannot be resolved.');
      }
      return retryUid;
    }
    return uid;
  }

  String get currentUid {
    final uid = _auth?.currentUser?.uid;
    if (uid == null) {
      throw Exception('User is not authenticated');
    }
    return uid;
  }
  
  // Mandatory base path for private collections: /artifacts/{appId}/users/{userId}
  Future<String> _getUserBasePath() async {
    await isReady;
    final uid = await getUserId();
    return 'artifacts/$_appId/users/$uid';
  }

  // Helper function to get the current month/year string (e.g., '2025-12')
  String getCurrentMonthYear() {
    return _monthYearFormat.format(DateTime.now());
  }

  // Predefined Categories (Hardcoded for initial structure)
  final List<Category> predefinedCategories = [
    Category(id: 'cat_food', name: 'cat_food'),
    Category(id: 'cat_trans', name: 'cat_trans'),
    Category(id: 'cat_salary', name: 'cat_salary'),
    Category(id: 'cat_rent', name: 'cat_rent'),
    Category(id: 'cat_savings', name: 'cat_savings'),
  ];
  
  // ------------------------------------------
  // 3. Collection References (CORRECTED PATHS)
  // ------------------------------------------
  
  // Base reference for all user-specific collections
  Future<DocumentReference> _getUserDocRef() async {
    await isReady;
    if (_db == null) {
      // This should not happen if isReady completed successfully
      throw Exception('Firestore instance not ready after awaiting initialization.');
    }
    return _db!.doc(await _getUserBasePath());
  }

  // CATEGORY COLLECTION REFERENCE**
  // Path: /artifacts/{appId}/users/{userId}/transaction_categories
  Future<CollectionReference> categoriesCollectionRef() async {
    final userDocRef = await _getUserDocRef();
    return userDocRef.collection('transaction_categories');
  }

  //  TRANSACTIONS COLLECTION REFERENCE**
  Future<CollectionReference> transactionsCollectionRef() async {
    final userDocRef = await _getUserDocRef();
    return userDocRef.collection('transactions');
  }

  // BUDGETS COLLECTION REFERENCE**
  Future<CollectionReference> budgetsCollectionRef() async {
    final userDocRef = await _getUserDocRef();
    return userDocRef.collection('budgets'); 
  }

  // SAVINGS GOAL DOCUMENT REFERENCE**
  Future<CollectionReference>  savingsGoalsCollectionRef() async {
    final userDocRef = await _getUserDocRef();
    return userDocRef.collection('savings_goals');
  }

  // ------------------------------------------
  // 4. CRUD Operations (Updated to use isReady guard)
  // ------------------------------------------
  
  Stream<List<Category>> streamCategories() async* {
    await isReady;
    final categoriesRef = await categoriesCollectionRef();  
    
    yield* categoriesRef
        .snapshots()
        .map((snapshot) {
          final List<Category> customCategories = snapshot.docs
              .map((doc) => Category.fromFirestore(doc))
              .toList();
          return [...predefinedCategories, ...customCategories];
        });
  }

  String getCategoryNameSync(String categoryId) {
    final predefined = predefinedCategories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(id: '', name: ''),
    );
    if (predefined.id.isNotEmpty) return predefined.name;

    // 2. Check the Cache (Instantly available in memory)
    final cached = _allCategoriesCache.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(id: '', name: 'Unknown'),
    );
    
    return cached.name;
  }

  Stream<List<Category>> streamCustomCategories() async* {
    await isReady; 
    final categoriesRef = await categoriesCollectionRef();
    
    yield* categoriesRef
        .orderBy('name', descending: false) 
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Category.fromFirestore(doc))
              .toList();
        });
  }
  
  Future<void> addCategory(String name) async {
    await isReady;
    final categoriesRef = await categoriesCollectionRef();  
    await categoriesRef.add({
      'name': name,
      'created_at': Timestamp.now(),
    });
  }

  Future<void> updateCategoryName(String categoryId, String newName) async {
    await isReady; 
    final categoriesRef = await categoriesCollectionRef();
    await categoriesRef.doc(categoryId).update({
      'name': newName,
    });
  }

  Future<void> addTransaction(Transaction transaction) async {
    await isReady; 

    try {
      final transactionsRef = await transactionsCollectionRef();
      transactionsRef.add(transaction.toFirestore());
      debugPrint('Transaction saved successfully: ${transaction.title}');
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      rethrow;
    }
  }

  // 1. Stream all transactions
  Stream<List<Transaction>> streamTransactions() async* {
    await isReady;
    final transactionsRef = await transactionsCollectionRef();

    yield* transactionsRef
        .orderBy('date', descending: true) 
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Transaction.fromFirestore(doc);
          }).toList();
        });
  }

  // 2. Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    await isReady;
    final transactionsRef = await transactionsCollectionRef();
    await transactionsRef.doc(transactionId).delete();
    debugPrint('Transaction $transactionId deleted');
  }

  // 3. Update transaction (for editing)
  Future<void> updateTransaction(Transaction transaction) async {
    await isReady;
    final transactionsRef = await transactionsCollectionRef();

    if (transaction.id == null) {
      throw Exception('Transaction ID is required for update');
    }
    
    await transactionsRef.doc(transaction.id!).update(
      transaction.toFirestore(),
    );
    debugPrint('Transaction ${transaction.id} updated');
  }

  // 4. Get categories by ID (for displaying category names)
  Future<String> getCategoryName(String categoryId) async {
    await isReady;
    
    final predefined = predefinedCategories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(id: '', name: 'Unknown'),
    );
    
    if (predefined.id.isNotEmpty) {
      return predefined.name;
    }
    
    final categoriesRef = await categoriesCollectionRef();
    final doc = await categoriesRef.doc(categoryId).get();
    if (doc.exists) {
      return Category.fromFirestore(doc).name;
    }
    
    return 'Unknown Category';
  }

  Future<List<Transaction>> getTransactionsInDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    await isReady;
    final transactionsRef = await transactionsCollectionRef();
    try {
      final query = transactionsRef
          .where('userId', isEqualTo: _currentUserId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return Transaction.fromFirestore(doc);
      }).toList();
    } catch (e) {
      debugPrint('Error getting transactions in date range: $e');
      return [];
    }
  }

  Stream<List<Transaction>> streamTransactionsInDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async* {
    await isReady;
    final transactionsRef = await transactionsCollectionRef();
    yield* transactionsRef
        .where('userId', isEqualTo: _currentUserId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Transaction.fromFirestore(doc);
          }).toList();
        });
  }

  Stream<List<Transaction>> streamMonthlyTransactions({String? monthYear}) async* {
  await isReady;

  // 1. Parse the string (e.g., "January 2026") into a DateTime object
  // If null, use the current month
  DateTime selectedDate = monthYear != null 
      ? DateFormat('MMMM yyyy').parse(monthYear) 
      : DateTime.now();

  DateTime startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
  DateTime endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);

  final transactionsRef = await transactionsCollectionRef();

  yield* transactionsRef
      .where('date', isGreaterThanOrEqualTo: startOfMonth)
      .where('date', isLessThanOrEqualTo: endOfMonth)
      .orderBy('date', descending: true) 
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .toList();
      });
  }
  

  Stream<List<Budget>> streamBudgets({String? monthYear}) async* {
    await isReady; 
    
    final currentMonth = monthYear ?? getCurrentMonthYear();
    final budgetsRef = await budgetsCollectionRef();
    
    yield* budgetsRef
        .where('monthYear', isEqualTo: currentMonth) 
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Budget.fromFirestore(doc))
              .toList();
        });
  }

  // Set Budget (Create or Update)
  Future<void> setBudget({
    required String categoryId,
    required double amount,
    required String monthYear,
  }) async {
    await isReady; 
    final budgetsRef = await budgetsCollectionRef();
    
    final budgetId = '${categoryId}_$monthYear';

    final budgetDoc = budgetsRef.doc(budgetId); 

    final newBudget = Budget(
      id: budgetId,
      userId: await getUserId(), 
      categoryId: categoryId,
      amount: amount,
      monthYear: monthYear,
    );
    
    // Use set() with merge: true to update or create
    await budgetDoc.set(newBudget.toJson(), SetOptions(merge: true));
  }

  Future<void> _ensureReady() async {
  try {
    await isReady.timeout(const Duration(seconds: 5));
  } catch (e) {
    throw Exception('Firestore Service failed to initialize in time: $e');
  }
}

  Stream<List<SavingsGoal>> streamSavingsGoals() async* {
    await isReady;
    final savingsGoalRef = await savingsGoalsCollectionRef();
    yield* savingsGoalRef
        .orderBy('deadline', descending: false) 
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return SavingsGoal.fromFirestore(doc);
          }).toList();
        });
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await isReady;

    try {
      final savingsGoalRef = await savingsGoalsCollectionRef();
      await savingsGoalRef.add(goal.toFirestore());
      debugPrint('Savings goal added: ${goal.name}');
    } catch (e) {
      debugPrint('Error adding savings goal: $e');
      rethrow;
    }
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _ensureReady();
    
    if (goal.id == null) {
      throw Exception('Goal ID required for update');
    }
    try {
      final savingsGoalRef = await savingsGoalsCollectionRef();
      await savingsGoalRef.doc(goal.id!).update(goal.toFirestore());
      debugPrint('Savings goal updated: ${goal.name}');
    } catch (e) {
      debugPrint('Error updating savings goal: $e');
      rethrow;
    }
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    await _ensureReady();
    final savingsGoalRef = await savingsGoalsCollectionRef();
    await savingsGoalRef.doc(goalId).delete();
  }

  // Update current amount when transactions are added
  Future<void> updateGoalProgress(String goalId, double amount) async {
    await isReady;
    final savingsGoalRef = await savingsGoalsCollectionRef();
    await savingsGoalRef.doc(goalId).update({
      'currentAmount': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

}
