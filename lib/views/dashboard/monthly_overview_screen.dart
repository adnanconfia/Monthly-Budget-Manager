import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/views/dashboard/widgets/expense_pie_chart.dart';
import 'package:daily_expense_tracker/views/dashboard/detailed_monthly_expense_page.dart';
import 'package:daily_expense_tracker/views/widgets/animated_counter.dart';
import 'package:daily_expense_tracker/views/widgets/icon_mapper.dart';

class MonthlyOverviewScreen extends StatelessWidget {
  const MonthlyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          '${DateFormat('MMMM yyyy').format(controller.selectedDate.value)} Overview',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        )),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAnimatedHeroTotals(controller, theme),
                  const SizedBox(height: 20),

                  // Dynamic Graph Ring Chart Card Representation
                  const Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: ExpensePieChart(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Progression Stats Track
                  _buildCategoryTrackingHeader(theme),
                  const SizedBox(height: 8),
                  _buildCategoryUsageGrid(controller, theme),
                  const SizedBox(height: 24),

                  // Symmetrical View Registry Trigger Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Registry',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.2),
                      ),
                      TextButton(
                        onPressed: () => Get.to(() => const DetailedMonthlyExpensePage()),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('See More Logs', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _buildOverviewTransactions(controller, theme),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeroTotals(ExpenseController controller, ThemeData theme) {
    return Obx(() {
      final savings = controller.remainingMonthlySavings;
      final totalSpent = controller.totalMonthlyExpenses;

      return Row(
        children: [
          Expanded(
            child: _buildIndicatorSummaryCard(
              title: "Current Outflow",
              value: totalSpent,
              color: Colors.redAccent,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildIndicatorSummaryCard(
              title: "Monthly Savings",
              value: savings,
              color: savings >= 0 ? Colors.green : Colors.red,
              theme: theme,
            ),
          )
        ],
      );
    });
  }

  Widget _buildIndicatorSummaryCard({
    required String title,
    required double value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: theme.disabledColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryTrackingHeader(ThemeData theme) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Categories Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.2),
        ),
      ],
    );
  }

  Widget _buildCategoryUsageGrid(ExpenseController controller, ThemeData theme) {
    return Obx(() {
      final activeCategories = controller.categories;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
        ),
        itemCount: activeCategories.length,
        itemBuilder: (context, index) {
          final cat = activeCategories[index];
          final spend = controller.getCategorySpend(cat.id);
          final percent = controller.getCategoryPercentage(cat.id);

          return Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.04)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(getIconFromString(cat.iconName), color: cat.color, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rs. ${spend.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Outlay', style: TextStyle(fontSize: 9, color: theme.disabledColor)),
                          Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 9, color: cat.color, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildOverviewTransactions(ExpenseController controller, ThemeData theme) {
    return Obx(() {
      final list = controller.monthlyExpenses;
      if (list.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          alignment: Alignment.center,
          child: Text(
            'Empty database registers',
            style: TextStyle(color: theme.disabledColor, fontSize: 12),
          ),
        );
      }

      final preview = list.take(2).toList();
      return Column(
        children: preview.map((expense) {
          final category = controller.categories.firstWhere(
                (c) => c.id == expense.categoryId,
            orElse: () => controller.categories.first,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: category.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(getIconFromString(category.iconName), color: category.color, size: 16),
              ),
              title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              trailing: Text(
                '- Rs. ${expense.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}