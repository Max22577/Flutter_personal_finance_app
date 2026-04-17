import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/features/dashboard/widgets/stats_card.dart';
import 'package:personal_fin/core/widgets/loading_state.dart';
import 'package:provider/provider.dart';
import '../view_models/quick_stats_view_model.dart';

class QuickStats extends StatelessWidget {
  final double height;
  const QuickStats({this.height = 200, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuickStatsViewModel(
        context.read<TransactionRepository>(),
      ),
      child: Consumer<QuickStatsViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) return const LoadingState();
          
          final lang = context.watch<LanguageProvider>();

          return SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: PageView(
                controller: PageController(viewportFraction: 0.9),
                padEnds: false,
                children: [
                  _buildCard(
                    title: lang.translate('this_month'),
                    income: vm.currentMonthIncome,
                    expenses: vm.currentMonthExpenses,
                  ),
                  _buildCard(
                    title: lang.translate('last_month'),
                    income: vm.lastMonthIncome,
                    expenses: vm.lastMonthExpenses,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({required String title, required double income, required double expenses}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: StatCard(title: title, income: income, expenses: expenses),
    );
  }
}