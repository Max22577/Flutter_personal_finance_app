import 'dart:async';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/features/dashboard/views/widgets/recent_transactions/transaction_display.dart';
import 'package:rxdart/rxdart.dart';

class RecentTransactionsViewModel {
  final TransactionRepository _repo;
  final CategoryRepository _catRepo;
  final CurrencyProvider _currencyProvider;
  final ExchangeRateService _exchangeService;
  final int _maxItems;

  RecentTransactionsViewModel({
    required TransactionRepository repo,
    required CategoryRepository catRepo,
    required CurrencyProvider currencyProvider,
    required ExchangeRateService exchangeService,
    int maxItems = 5,
  })  : _repo = repo,
        _catRepo = catRepo,
        _currencyProvider = currencyProvider,
        _exchangeService = exchangeService,
        _maxItems = maxItems;

  // The single reactive source of truth
  Stream<List<TransactionDisplay>> get recentTransactionsStream {
    return Rx.combineLatest3(
      _repo.getRecentTransactions(_maxItems), 
      _currencyProvider.currencyStream,
      _catRepo.allCategoriesStream,
      (transactions, currencyCode, categories) {
        final catMap = {for (var c in categories) c.id: c.name};

        return transactions.map((tx) {
          final convertedAmount = _exchangeService.fromBase(tx.baseAmount, currencyCode);
          return TransactionDisplay(
            tx.copyWith(amount: convertedAmount),
            catMap[tx.categoryId] ?? 'General',
          );
        }).toList();
      },
    );
  }
}