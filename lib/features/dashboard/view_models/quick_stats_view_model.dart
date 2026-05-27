import 'dart:async';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:rxdart/rxdart.dart';

class QuickStatsViewModel {
  final TransactionRepository _repo;
  final ExchangeRateService _exchangeService;
  final CurrencyProvider _currencyProvider;

  double currentMonthIncome = 0;
  double currentMonthExpenses = 0;
  double lastMonthIncome = 0;
  double lastMonthExpenses = 0;
  bool isLoading = true;

  QuickStatsViewModel(this._repo, this._exchangeService, this._currencyProvider); 

  Stream<QuickStatsData> get statsStream {
    return Rx.combineLatest2(
      _repo.transactionsStream,
      _currencyProvider.currencyStream,
      (transactions, currencyCode) {
        return _calculate(transactions, currencyCode);
      },
    );
  }

  QuickStatsData _calculate(List<Transaction> transactions, String currencyCode) {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final last = DateTime(now.year, now.month - 1);

    double cInc = 0, cExp = 0, lInc = 0, lExp = 0;

    for (final t in transactions) {
      final tMonth = DateTime(t.date.year, t.date.month);
      final val = _exchangeService.fromBase(t.baseAmount, currencyCode);
      
      if (tMonth.isAtSameMomentAs(current)) {
        t.type == 'Income' ? cInc += val : cExp += val;
      } else if (tMonth.isAtSameMomentAs(last)) {
        t.type == 'Income' ? lInc += val : lExp += val;
      }
    }
    return QuickStatsData(cInc, cExp, lInc, lExp);
  }
}

class QuickStatsData {
  final double cInc, cExp, lInc, lExp;
  QuickStatsData(this.cInc, this.cExp, this.lInc, this.lExp);
}