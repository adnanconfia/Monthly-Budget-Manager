import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/controllers/theme_controller.dart';
import 'package:daily_expense_tracker/views/category/category_details_screen.dart';
import 'package:daily_expense_tracker/views/history/history_screen.dart';
import 'package:daily_expense_tracker/views/widgets/add_expense_sheet.dart';
import 'package:daily_expense_tracker/views/widgets/icon_mapper.dart';
import 'package:daily_expense_tracker/views/widgets/income_input_dialog.dart';
import 'package:daily_expense_tracker/views/dashboard/widgets/expense_pie_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    final themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final activeDate = controller.selectedDate.value;
          final monthYearStr = DateFormat('MMMM yyyy').format(activeDate);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              // 🌟 ANIMATED MONTH & YEAR SUBTITLE
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, -0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey<String>(monthYearStr),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 13,
                      color: theme.colorScheme.primary.withOpacity(0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      monthYearStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Compact Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, Welcome back',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Dashboard Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.cardTheme.color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_road_rounded, size: 18),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const IncomeInputDialog(isFirstTime: false),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Obx(() => IconButton(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.cardTheme.color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(themeController.isDarkMode.value ? Icons.light_mode : Icons.dark_mode, size: 18),
                        onPressed: themeController.toggleTheme,
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Compact Grid-based Financial Stats Cards
              Obx(() {
                final savings = controller.remainingSavings;
                final isNegative = savings < 0;
                return GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatPill(
                      title: 'INCOME',
                      val: 'Rs. ${controller.income.value.toStringAsFixed(0)}',
                      color: const Color(0xFF6366F1),
                      icon: Icons.south_west_rounded,
                      theme: theme,
                      onTap: () {
                        // 👈 Clicking Income card opens the Income Input Dialog
                        showDialog(
                          context: context,
                          builder: (context) => const IncomeInputDialog(isFirstTime: false),
                        );
                      },
                    ),
                    _buildStatPill(
                      title: 'EXPENSE',
                      val: 'Rs. ${controller.totalExpenses.toStringAsFixed(0)}',
                      color: const Color(0xFFF43F5E),
                      icon: Icons.north_east_rounded,
                      theme: theme,
                    ),
                    _buildStatPill(
                      title: 'SAVINGS',
                      val: 'Rs. ${savings.toStringAsFixed(0)}',
                      color: isNegative ? Colors.orange : const Color(0xFF10B981),
                      icon: isNegative ? Icons.warning_amber : Icons.offline_bolt_rounded,
                      theme: theme,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // 3. Compact Spend Allocation Pie Card
              const Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: ExpensePieChart(),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Usage Slider Line (Simplified Progress Indicator)
              Obx(() {
                final percentage = controller.totalPercentSpent / 100.0;
                final cappedPercentage = percentage.clamp(0.0, 1.0);
                final warningColor = controller.remainingSavings < 0 ? Colors.red : const Color(0xFF6366F1);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.query_stats_rounded, color: warningColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Usage Outlay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                Text(
                                  '${controller.totalPercentSpent.toStringAsFixed(1)}%',
                                  style: TextStyle(color: warningColor, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: cappedPercentage,
                                minHeight: 6,
                                backgroundColor: theme.disabledColor.withOpacity(0.1),
                                color: warningColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // 5. Category-wise Grids (Compact Cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Categories Tracking', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Get.to(() => const HistoryScreen()),
                    child: const Text('View Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              Obx(() {
                final _ = controller.expenses.length;
                final __ = controller.income.value;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: controller.categories.length,
                  itemBuilder: (context, index) {
                    final cat = controller.categories[index];
                    final spend = controller.getCategorySpend(cat.id);
                    return Card(
                      child: InkWell(
                        onTap: () => Get.to(() => CategoryDetailsScreen(category: cat)),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: cat.color.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(getIconFromString(cat.iconName), color: cat.color, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rs. ${spend.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    '${controller.getCategoryPercentage(cat.id).toStringAsFixed(1)}%',
                                    style: TextStyle(color: theme.disabledColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: theme.scaffoldBackgroundColor,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddExpenseSheet(),
            );
          },
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text('Add New Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required String title,
    required String val,
    required Color color,
    required IconData icon,
    required ThemeData theme,
    VoidCallback? onTap, // 👈 Added optional onTap callback parameter
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: theme.disabledColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  val,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}