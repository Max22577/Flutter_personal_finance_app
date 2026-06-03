import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/core/shared_widgets/loading_state.dart';
import 'package:personal_fin/features/dashboard/views/widgets/empty_chart_state.dart';
import 'package:provider/provider.dart';
import '../../../view_models/spending_chart_view_model.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key});

  static const List<Color> _vibrantColors = [
    Color(0xFFFF007F), // Vivid Pink
    Color(0xFF00F5D4), // Bright Teal
    Color(0xFF7B2CBF), // Electric Purple
    Color(0xFFFF9F1C), // Bright Orange
    Color(0xFF06D6A0), // Emerald Green
    Color(0xFF5bc0be), // Soft Cyan
    Color(0xFFff0054), // Magenta
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpendingChartViewModel>(
      create: (_) => SpendingChartViewModel(
        context.read<TransactionRepository>(),
        context.read<CurrencyProvider>(),
      ),
      child: const _CategoryPieChartConsumer(colorsList: _vibrantColors),
    );
  }
}

class _CategoryPieChartConsumer extends StatelessWidget {
  final List<Color> colorsList;

  const _CategoryPieChartConsumer({required this.colorsList});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpendingChartViewModel>();

    return StreamBuilder<Map<String, double>>(
      stream: vm.spendingMapStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingState());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _ChartCardWrapper(
            child: Center(
              child: EmptyChartState(textMessage: "No transactions found for this month."),
            ),
          );
        }

        final spendingList = snapshot.data!;
        
        return _ChartCardWrapper(
          child: _ActiveChartContent(
            categoryData: spendingList,
            colorsList: colorsList,
          ),
        );
      },
    );   
  }
}

class _ActiveChartContent extends StatefulWidget {
  final Map<String, double> categoryData;
  final List<Color> colorsList;

  const _ActiveChartContent({
    required this.categoryData,
    required this.colorsList,
  });

  @override
  State<_ActiveChartContent> createState() => _ActiveChartContentState();
}

class _ActiveChartContentState extends State<_ActiveChartContent> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _titleFadeIn;
  late final Animation<double> _chartLoad;
  late final Animation<double> _legendFadeIn;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // Complete transition timeline window
    );

    // Sequence 1: Title slides up immediately
    _titleFadeIn = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutQuad),
    );

    // Sequence 2: Chart sweeps out clockwise following title onset
    _chartLoad = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.20, 0.75, curve: Curves.easeOutCubic),
    );

    // Sequence 3: Legend rows settle in cleanly at the finish line
    _legendFadeIn = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutQuad),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeFont = textScaler.scale(1) > 1.3;

    // Helper sliding translation builder offset tween configuration
    Animation<Offset> slideTween(Animation<double> parentAnimation) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.15),
        end: Offset.zero,
      ).animate(parentAnimation);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITLE ANIMATION LAYER
        FadeTransition(
          opacity: _titleFadeIn,
          child: SlideTransition(
            position: slideTween(_titleFadeIn),
            child: Text(
              "Monthly Spending Breakdown",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Flex(
          direction: isLargeFont ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // CHART ANIMATION LAYER
            AnimatedBuilder(
              animation: _chartLoad,
              builder: (context, child) {
                return SizedBox(
                  height: isLargeFont ? 200 : 160,
                  width: isLargeFont ? double.infinity : 160,
                  child: _PieChartGraphic(
                    categoryData: widget.categoryData,
                    colorsList: widget.colorsList,
                    animProgress: _chartLoad.value, // Pass scaling timeline factor downstream
                  ),
                );
              },
            ),
            if (!isLargeFont) const SizedBox(width: 24),
            if (isLargeFont) const SizedBox(height: 24),
            
            // LEGEND ANIMATION LAYER
            Expanded(
              flex: isLargeFont ? 0 : 1,
              child: FadeTransition(
                opacity: _legendFadeIn,
                child: SlideTransition(
                  position: slideTween(_legendFadeIn),
                  child: _ChartLegend(
                    categoryData: widget.categoryData,
                    colorsList: widget.colorsList,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// SUB-COMPONENTS (CHART & LEGEND)
class _PieChartGraphic extends StatelessWidget {
  final Map<String, double> categoryData;
  final List<Color> colorsList;
  final double animProgress;

  const _PieChartGraphic({
    required this.categoryData,
    required this.colorsList,
    required this.animProgress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: textScaler.scale(32),
        startDegreeOffset: 270, // Start drawing segments at 12 o'clock
        sections: _generateSections(colors, textScaler),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(ColorScheme colors, TextScaler textScaler) {
    final totalExpenses = categoryData.values.fold(0.0, (sum, item) => sum + item);
    int index = 0;

    return categoryData.entries.map((entry) {
      final color = colorsList[index % colorsList.length];
      index++;

      final percentage = totalExpenses > 0 ? entry.value / totalExpenses : 0.0;
      final bool shouldShowBadge = percentage >= 0.05 && animProgress > 0.6;

      return PieChartSectionData(
        color: color,
        // Scale values sequentially alongside animation timelines to trigger native clockwise sweep
        value: entry.value * animProgress, 
        radius: textScaler.scale(42),
        showTitle: false,
        badgeWidget: shouldShowBadge
            ? Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                ),
              )
            : null,
        badgePositionPercentageOffset: 0.60,
      );
    }).toList();
  }
}

class _ChartLegend extends StatelessWidget {
  final Map<String, double> categoryData;
  final List<Color> colorsList;

  const _ChartLegend({
    required this.categoryData,
    required this.colorsList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int index = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: categoryData.entries.map((entry) {
        final color = colorsList[index % colorsList.length];
        index++;

        return IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // THIN VERTICAL DIVIDER REPLACEMENT LINE
              Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              const SizedBox(width: 8),
              
              // STACKED METRICS LABELS COLUMN
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Currency Display safely relocated under respective category name
                  CurrencyDisplay(
                    amount: entry.value,
                    compact: false,
                    isExpense: true,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ChartCardWrapper extends StatelessWidget {
  final Widget child;

  const _ChartCardWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}