import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/core/widgets/shared/loading_state.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';
import 'stats_card.dart';

final FirestoreService _firestoreService = FirestoreService.instance;

class QuickStats extends StatefulWidget {
  final double height;

  const QuickStats({this.height = 120, super.key});

  @override
  State<QuickStats> createState() => _QuickStatsState();
}

class _QuickStatsState extends State<QuickStats> {
  double _currentMonthIncome = 0;
  double _currentMonthExpenses = 0;
  double _lastMonthIncome = 0;
  double _lastMonthExpenses = 0;
  bool _isLoading = true;
  StreamSubscription? _transactionSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _transactionSubscription = _firestoreService.streamTransactions().listen(
      (transactions) {
        _calculateStats(transactions);
      },
      onError: (e) {
        debugPrint('Error loading quick stats: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _calculateStats(List<Transaction> transactions) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    
    double currentIncome = 0;
    double currentExpenses = 0;
    double lastIncome = 0;
    double lastExpenses = 0;

    for (final transaction in transactions) {
      final transactionMonth = DateTime(
        transaction.date.year,
        transaction.date.month,
      );

      if (transactionMonth.isAtSameMomentAs(currentMonth)) {
        if (transaction.type == 'Income') {
          currentIncome += transaction.amount;
        } else {
          currentExpenses += transaction.amount;
        }
      } else if (transactionMonth.isAtSameMomentAs(lastMonth)) {
        if (transaction.type == 'Income') {
          lastIncome += transaction.amount;
        } else {
          lastExpenses += transaction.amount;
        }
      }
    }

    if (mounted) {
      setState(() {
        _currentMonthIncome = currentIncome;
        _currentMonthExpenses = currentExpenses;
        _lastMonthIncome = lastIncome;
        _lastMonthExpenses = lastExpenses;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingState();
    final lang = context.watch<LanguageProvider>();

    return Column(
      children: [
        SizedBox(
          height: 200, 
          child: PageView(
            controller: PageController(viewportFraction: 0.9),
            padEnds: false,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StatCard(
                  title: lang.translate('this_month'),
                  income: _currentMonthIncome,
                  expenses: _currentMonthExpenses,
                ),
              ),
              StatCard(
                title: lang.translate('last_month'),
                income: _lastMonthIncome,
                expenses: _lastMonthExpenses,
              ),
            ],
          ),
        ),
      ],
    );
  }
}