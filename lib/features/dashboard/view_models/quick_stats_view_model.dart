import 'dart:async';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:rxdart/rxdart.dart';

class QuickStatsViewModel {
  final MonthlyDataRepository _repo;
  final CurrencyProvider _currencyProvider;

  QuickStatsViewModel(this._repo, this._currencyProvider);

  Stream<QuickStatsData> get statsStream {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    return _currencyProvider.currencyStream.switchMap((currency) {
      return _repo.streamReviewData(currentMonth, currency).map((dataList) {
        final current = dataList[0];
        final previous = dataList[1];
        
        return QuickStatsData(
          current.income, current.expenses,
          previous.income, previous.expenses,
        );
      });
    });
  }
}

class QuickStatsData {
  final double cInc, cExp, lInc, lExp;
  QuickStatsData(this.cInc, this.cExp, this.lInc, this.lExp);
}