import 'package:flutter/material.dart';
import 'package:personal_fin/core/widgets/dashboard/income_expense.dart';
import 'package:personal_fin/core/widgets/dashboard/monthly_review.dart';
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
                          const Text('Error loading monthly data'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // Trigger a rebuild to retry loading data
                              });
                            },
                            child: const Text('Retry'),
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
                          customTitle: 'This Month',
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
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 10),
                    // In a real app, this would be buttons for 'Add Budget', 'Set Goal', etc.
                    ListTile(leading: Icon(Icons.add_to_photos), title: Text('Set Next Budget')),
                    ListTile(leading: Icon(Icons.star_border), title: Text('Review Savings Goals')),
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