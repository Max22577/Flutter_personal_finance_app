import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/services/firestore_service.dart';
import 'package:personal_fin/core/widgets/shared/currency_display.dart';
import 'package:personal_fin/core/widgets/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/savings/progress_chart.dart';
import '../../models/savings.dart';
import 'set_savings_goal.dart';


final FirestoreService _firestoreService = FirestoreService.instance;

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<SavingsGoal> _goals = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _goalsSubscription;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    final lang = context.read<LanguageProvider>();
    _goalsSubscription = _firestoreService.streamSavingsGoals().listen(
      (goals) {
        if (mounted) {
          setState(() {
            _goals = goals;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _errorMessage = '${lang.translate('failed_to_load_goals')} $e';
            _isLoading = false;
          });
        }
      },
    );
  }

  void _addGoal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SetGoalPage(),
      ),
    );
  }

  void _editGoal(SavingsGoal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SetGoalPage(existingGoal: goal),
      ),
    );
  }

  double get _totalTarget {
    return _goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  double get _totalSaved {
    return _goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  double get _overallProgress {
    if (_totalTarget == 0) return 0;
    return (_totalSaved / _totalTarget).clamp(0.0, 1.0);
  }

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.watch<LanguageProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28), // Softer, more modern corners
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Icon and Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.insights_rounded, color: colors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  lang.translate('savings_overview'),
                  style: textTheme.labelMedium?.copyWith( 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row with Dividers
          IntrinsicHeight( // Ensures vertical dividers match column height
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatItem(lang.translate('goals'), Text(_goals.length.toString(), style: _valueStyle(textTheme))),
                    _buildVerticalDivider(colors), // Custom vertical divider
                    _buildStatItem(lang.translate('progress'), Text('${(_overallProgress * 100).toStringAsFixed(0)}%', 
                        style: _valueStyle(textTheme).copyWith(color: colors.primary))),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: colors.outlineVariant.withValues(alpha: 0.1)),
                ),
                Row(
                  children: [
                    _buildStatItem(lang.translate('target'), CurrencyDisplay(amount: _totalTarget, compact: true, style: _valueStyle(textTheme))),
                    _buildVerticalDivider(colors),
                    _buildStatItem(lang.translate('saved'), CurrencyDisplay(amount: _totalSaved, compact: true, style: _valueStyle(textTheme))),
                  ],
                ),
              ],
            )
          ),
        ],
      ),
    );
  }

  // Helper for consistent value styling
  TextStyle _valueStyle(TextTheme textTheme) => textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );

  Widget _buildVerticalDivider(ColorScheme colors) {
    return VerticalDivider(
      color: colors.outlineVariant.withValues(alpha: 0.2),
      thickness: 1,
      indent: 8,
      endIndent: 8,
    );
  }

  Widget _buildStatItem(String label, Widget valueWidget) {
    final theme = Theme.of(context);
    
    return Expanded( // Ensures even distribution
      child: Column(
        children: [
          valueWidget,
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 9,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final illustrationTheme = Theme.of(context).extension<IllustrationTheme>();
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 50.0, end: 0.0), 
        duration: const Duration(seconds: 1),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value), 
            child: child,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/savings.png', 
              width: 180,
              height: 180,
              color: illustrationTheme?.tintColor,
              colorBlendMode: illustrationTheme?.blendMode,
              
            ),
          
            const SizedBox(height: 20),
            Text(
              lang.translate('no_goals_yet'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              lang.translate('start_by_creating'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200, 
              child: ElevatedButton.icon(
                onPressed: _addGoal,
                icon: const Icon(Icons.add),
                label: Text(lang.translate('create_goal')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                
              ),
            ),
          ],  
        )
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    final lang = context.watch<LanguageProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              lang.translate('failed_to_load_goals'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? lang.translate('unknown_error'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadGoals,
              child: Text(lang.translate('retry')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(lang.translate('savings_goals'), 

          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
          )
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_goals.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addGoal,
              tooltip: lang.translate('add_goal_tooltip'),
            ),
        ],
      ),
      body: _goals.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                _goalsSubscription?.cancel();
                setState(() => _isLoading = true);
                _loadGoals();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 20),

                  Text(
                    lang.translate('your_goals'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._goals.map((goal) {
                    return GestureDetector(
                      onTap: () => _editGoal(goal),
                      child: Column(
                        children: [
                          ProgressChartWidget(goal: goal),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
      floatingActionButton: _goals.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: _addGoal,
            heroTag: 'addGoal',
            icon: const Icon(Icons.add),
            label: Text(lang.translate('new_goal')),
          )      
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}