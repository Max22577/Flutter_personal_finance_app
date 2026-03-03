import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/widgets/dashboard/income_expense.dart';
import 'package:personal_fin/core/widgets/dashboard/monthly_review.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/services/monthly_data_service.dart';
import '../../core/widgets/dashboard/quick_stats.dart';
import '../../core/widgets/dashboard/recent_transactions.dart';
import '../../models/monthly_data.dart';
import 'monthly_review_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final MonthlyDataService _monthlyDataService = MonthlyDataService();
  late Stream<List<MonthlyData?>> _monthlyDataStream;
  
  @override
  void initState() {
    super.initState();
    _initStreams();  
  }

  void _initStreams() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);

    _monthlyDataStream = Rx.combineLatest2(
      _monthlyDataService.streamMonthlyData(currentMonth),
      _monthlyDataService.streamMonthlyData(previousMonth),
      (MonthlyData current, MonthlyData previous) => [current, previous],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();

    return  Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Monthly Overview Card
            StreamBuilder<List<MonthlyData?>>(
              stream: _monthlyDataStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 40),
                          const SizedBox(height: 16),
                          Text(lang.translate('error_loading_monthly_data')),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // Trigger a rebuild to retry loading data
                              });
                            },
                            child: Text(lang.translate('retry')),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final currentData = snapshot.data![0] as MonthlyData;
                final previousData = snapshot.data![1] ;
                
                return MonthlyReview(
                  monthlyData: currentData,
                  previousMonthData: previousData,
                  onTap: () {
                    // Navigate to full monthly review page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MonthlyReviewPage(
                          month: DateTime.now(),
                          customTitle: lang.translate('this_month'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            const IncomeExpensesGraph(daysToShow: 7, height: 250),
        
            const SizedBox(height: 40),

            const QuickStats(height: 220),

            const SizedBox(height: 30),

            RecentTransactions(
              maxItems: 5,
              onViewAll: () {
                // Navigate to transactions page
                // Navigator.push(context, MaterialPageRoute(...));
              },
            ),

            const SizedBox(height: 10),
            // --- 3. Additional Card Placeholder ---
            Card(
              elevation: 4,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.translate('quick_actions'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 10),
                    // In a real app, this would be buttons for 'Add Budget', 'Set Goal', etc.
                    ListTile(leading: Icon(Icons.add_to_photos), title: Text(lang.translate('set_next_budget'))),
                    ListTile(leading: Icon(Icons.star_border), title: Text(lang.translate('review_savings_goals'))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 140),

          ],
        ),
      )
    );
  }
}