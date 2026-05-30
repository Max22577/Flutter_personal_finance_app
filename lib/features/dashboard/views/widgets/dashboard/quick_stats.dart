import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/exchange_rate_service.dart';
import 'package:personal_fin/features/dashboard/views/widgets/dashboard/quick_stats/stats_card.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:provider/provider.dart';
import '../../../view_models/quick_stats_view_model.dart';

class QuickStats extends StatelessWidget {
  final double height;
  const QuickStats({this.height = 200, super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    // Calculate an adaptive height based on the text scale
    // This ensures the PageView container grows as the text inside it grows.
    final adaptiveHeight = textScaler.scale(height);

    return Provider(
      create: (_) => QuickStatsViewModel(
        context.read<TransactionRepository>(),
        context.read<ExchangeRateService>(),
        context.read<CurrencyProvider>(),
      ),
      child: Builder(builder: (context) {
        final vm = context.read<QuickStatsViewModel>();
        final lang = context.watch<LanguageProvider>();

        return StreamBuilder<QuickStatsData>(
          stream: vm.statsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingState();
            
            final stats = snapshot.data!;

            return SizedBox(
              height: adaptiveHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: PageView(
                  controller: PageController(viewportFraction: 0.9),
                  padEnds: false,
                  children: [
                    _buildCard(
                      title: lang.translate('this_month'),
                      income: stats.cInc,
                      expenses: stats.cExp,
                    ),
                    _buildCard(
                      title: lang.translate('last_month'),
                      income: stats.lInc,
                      expenses: stats.lExp,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildCard({required String title, required double income, required double expenses}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: StatCard(title: title, income: income, expenses: expenses),
    );
  }
}