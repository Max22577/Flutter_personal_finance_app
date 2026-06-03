
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/repositories/monthly_data_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/shared_widgets/empty_state.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:personal_fin/core/theme/app_theme.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/core/shared_widgets/custom_appbar.dart';
import 'package:personal_fin/features/dashboard/view_models/monthly_review_view_model.dart';
import 'package:personal_fin/features/dashboard/views/widgets/monthly_review/category_spending_card.dart';
import 'package:personal_fin/features/dashboard/views/widgets/monthly_review/monthly_trends_card.dart';
import 'package:personal_fin/features/dashboard/views/widgets/monthly_review_summary.dart';
import 'package:personal_fin/models/monthly_data.dart';
import 'package:provider/provider.dart';


class MonthlyReviewPage extends StatelessWidget {
  final DateTime? month;
  final String? customTitle;

  const MonthlyReviewPage({this.month, this.customTitle, super.key});

  @override
  Widget build(BuildContext context) {
    final targetMonth = month ?? DateTime.now();

    return ChangeNotifierProvider<MonthlyReviewViewModel>(
      create: (context) => MonthlyReviewViewModel(
        context.read<MonthlyDataRepository>(),
        context.read<TransactionRepository>(),
        context.read<CurrencyProvider>(),
        targetMonth,
      ),
      child: _MonthlyReviewScaffold(targetMonth: targetMonth),
    );
  }
}


class _MonthlyReviewScaffold extends StatelessWidget {
  final DateTime targetMonth;

  const _MonthlyReviewScaffold({required this.targetMonth});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'monthly_review_title',
        isRootNav: false,
        isOverGradient: true,
      ),
      body: _MonthlyReviewBody(targetMonth: targetMonth),
    );
  }
}

class _MonthlyReviewBody extends StatelessWidget {
  final DateTime targetMonth;

  const _MonthlyReviewBody({required this.targetMonth});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MonthlyReviewViewModel>();
    final lang = context.watch<LanguageProvider>();
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    // Safely look up system status bar heights manually
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

  return StreamBuilder<List<MonthlyData>>(
    stream: vm.getReviewDataStream(targetMonth),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return SizedBox(
          height: textScaler.scale(150),
          child: const Center(child: LoadingState()),
        );
      }
      
      if (snapshot.hasError) {
        return SizedBox(
          height: textScaler.scale(160),
          child: Center(
            child: EmptyState(
              icon: Icons.error_outline,
              title: lang.translate('error_loading_monthly_data'),
              message: snapshot.error.toString(),
              actionText: lang.translate('retry'),
              onAction: () {},
            ),
          ),
        );
      }

      final data = snapshot.data;
      if (data == null || data.isEmpty) {
        return SizedBox(
          height: textScaler.scale(160),
          child: Center(
            child: EmptyState(
              icon: Icons.info_outline,
              title: lang.translate('no_monthly_data'),
              message: 'Please ensure you have transactions for the current month.',
              actionText: lang.translate('retry'),
              onAction: () {},
            ),
          ),
        );
      }

      const baseDuration = Duration(milliseconds: 600);
      const baseCurve = Curves.easeOutQuint;

      return LayoutBuilder(
        builder: (context, constraints) {
          final double gradientBackdropHeight = statusBarHeight + kToolbarHeight + textScaler.scale(160);

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: gradientBackdropHeight + textScaler.scale(20), // Added buffer
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, Color.lerp(colors.primary, colors.secondary, 0.5)!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    textScaler.scale(16), 
                    statusBarHeight + kToolbarHeight + textScaler.scale(8), 
                    textScaler.scale(16), 
                    textScaler.scale(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: textScaler.scale(120), 
                        ),
                        child: FadeInUp(
                          duration: baseDuration,
                          curve: baseCurve,
                          delay: const Duration(milliseconds: 0),
                          child: MonthlyReviewSummary(
                            monthlyData: data[0],
                            previousMonthData: data[1],
                            onTap: () => _showMonthlyDetails(context, data[0]),
                          ),
                        ),
                      ),
                      SizedBox(height: textScaler.scale(32)),
                      FadeInUp(
                        duration: baseDuration,
                        curve: baseCurve,
                        delay: const Duration(milliseconds: 150),
                        child: const MonthlyTrendsCard(),
                      ),
                      SizedBox(height: textScaler.scale(16)),
                      FadeInUp(
                        duration: baseDuration,
                        curve: baseCurve,
                        delay: const Duration(milliseconds: 300),
                        child: const CategorySpendingCarousel(),
                      ),
                      SizedBox(height: textScaler.scale(120))
                      
                    ],
                  ),
                ),
              ),
            ]
          );
        }
      );   
    });
  }

  void _showMonthlyDetails(BuildContext context, MonthlyData data) {
    final theme = Theme.of(context);
    final financialColors = theme.extension<FinancialColors>()!;
    final lang = context.read<LanguageProvider>();
    final monthName = DateFormat('MMMM', lang.localeCode).format(data.month);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$monthName ${lang.translate('summary_title')}',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: lang.translate('income_label'),
              value: data.income,
              color: financialColors.income,
            ),
            _DetailRow(
              label: lang.translate('expenses_label'),
              value: data.expenses,
              color: financialColors.expense,
              isExpense: true,
            ),
            const Divider(height: 24),
            _DetailRow(
              label: lang.translate('net_profit'),
              value: data.net,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}


class _DetailRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isExpense;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    this.isExpense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          CurrencyDisplay(
            amount: value,
            isExpense: isExpense,
            compact: false,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}