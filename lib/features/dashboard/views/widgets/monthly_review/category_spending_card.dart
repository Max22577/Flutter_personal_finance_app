import 'package:flutter/material.dart';
import 'package:personal_fin/core/shared_widgets/currency_display.dart';
import 'package:personal_fin/core/utils/category_icon_helper.dart';
import 'package:personal_fin/features/dashboard/view_models/monthly_review_view_model.dart';
import 'package:personal_fin/models/state_models/category_spending.dart';
import 'package:provider/provider.dart';

class CategorySpendingCarousel extends StatelessWidget {
  const CategorySpendingCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonthlyReviewViewModel>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title padding matches standard app layout boundaries
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Spending by Category",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        StreamBuilder<List<CategorySpending>>(
          stream: vm.categorySpendingStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "No spending recorded for this month.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            // Fixed height container keeps layout stable during scrolls
            return SizedBox(
              height: 140, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final catColor = CategoryIconHelper.getColor(item.category, theme.colorScheme);
                  final catIcon = CategoryIconHelper.getIcon(item.category);

                  return Container(
                    width: 160, // Consistent structural width for internal text alignment
                    margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Row: Dynamic Monochromatic Icon Badge & Percentage
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(catIcon, color: catColor, size: 18),
                              ),
                              Text(
                                "${(item.percentage * 100).toStringAsFixed(0)}%",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          // Middle Stack: Metadata Labeling
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              CurrencyDisplay(
                                amount: item.totalAmount,
                                isExpense: true,
                              ),
                            ],
                          ),
                          
                          // Bottom Row: Custom Colored Track Bar Indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: item.percentage,
                              minHeight: 4,
                              backgroundColor: catColor.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(catColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}