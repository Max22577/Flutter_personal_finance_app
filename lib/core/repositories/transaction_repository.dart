import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../models/transaction.dart';
import '../services/firestore_service.dart';

class TransactionRepository {
  final FirestoreService _service = FirestoreService.instance;
  
  // The "Master Stream"
  late final BehaviorSubject<List<Transaction>> _transactionSubject;
  StreamSubscription? _firestoreSub;

  TransactionRepository() {
    _transactionSubject = BehaviorSubject<List<Transaction>>();
    _init();
  }

  void _init() {
    _firestoreSub = _service.streamTransactions().listen(
      (data) => _transactionSubject.add(data),
      onError: (e) => _transactionSubject.addError(e),
    );
  }

  // ViewModels call this to get the data
  Stream<List<Transaction>> get transactionsStream => _transactionSubject.stream;

  Future<void> refresh() async {
    _firestoreSub?.cancel();
    _init();
    await _transactionSubject.first.timeout(const Duration(seconds: 5));
  }

  // Clean up
  void dispose() {
    _firestoreSub?.cancel();
    _transactionSubject.close();
  }
}