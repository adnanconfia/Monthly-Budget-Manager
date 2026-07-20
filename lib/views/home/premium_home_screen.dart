import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/views/dashboard/dashboard_screen.dart';

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen> {
  final int startYear = 2025;
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _yearBarScrollController = ScrollController();

  int _selectedYearHeader = DateTime.now().year;

  bool _isMonthLocked(int year, int month) {
    final now = DateTime.now();
    if (year > now.year) return true;
    if (year == now.year && month > now.month) return true;
    return false;
  }

  void _scrollToYear(int year, int index) {
    setState(() {
      _selectedYearHeader = year;
    });

    final int yearIndex = year - startYear;
    if (yearIndex >= 0) {
      final double estimatedOffset = yearIndex * 370.0;
      _mainScrollController.animateTo(
        estimatedOffset.clamp(0.0, _mainScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    final double targetChipOffset = index * 80.0;
    _yearBarScrollController.animateTo(
      targetChipOffset.clamp(0.0, _yearBarScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseCtrl = Get.find<ExpenseController>();
    final currentNow = DateTime.now();

    final totalYearsCount = (currentNow.year - startYear) + 1;
    final yearsList = List.generate(totalYearsCount, (i) => startYear + i);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Timeline',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🌟 TOP STICKY YEAR BAR (Height & Padding Reduced)
            Container(
              height: 42, // Height 52 -> 42
              padding: const EdgeInsets.symmetric(vertical: 2.0), // Padding reduced
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ListView.builder(
                controller: _yearBarScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: yearsList.length,
                itemBuilder: (context, idx) {
                  final year = yearsList[idx];
                  final isSelected = year == _selectedYearHeader;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact, // Compact chip layout
                      label: Text(
                        '$year',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor.withOpacity(0.2),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          _scrollToYear(year, idx);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // 📜 TIMELINE LIST (Gap Reduced)
            Expanded(
              child: ListView.builder(
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 12.0), // Top padding 12.0 -> 4.0
                itemCount: totalYearsCount,
                itemBuilder: (context, yearIndex) {
                  final year = startYear + yearIndex;
                  final isCurrentYear = year == currentNow.year;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 10.0, left: 4.0, right: 4.0), // Padding tightened
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isCurrentYear
                                    ? theme.colorScheme.primary
                                    : theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isCurrentYear
                                    ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                                    : null,
                              ),
                              child: Text(
                                '$year',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isCurrentYear
                                      ? Colors.white
                                      : theme.textTheme.titleMedium?.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Divider(
                                color: isCurrentYear
                                    ? theme.colorScheme.primary.withOpacity(0.4)
                                    : theme.dividerColor.withOpacity(0.2),
                                thickness: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, monthIdx) {
                          final month = monthIdx + 1;
                          final isLocked = _isMonthLocked(year, month);
                          final dateObj = DateTime(year, month);
                          final monthName = DateFormat('MMMM').format(dateObj);
                          final isCurrentMonth =
                              year == currentNow.year && month == currentNow.month;

                          return Obx(() {
                            final income = expenseCtrl.getIncomeForMonth(month, year);
                            final expense = expenseCtrl.getMonthlyExpensesSum(month, year);
                            final balance = income - expense;

                            return InkWell(
                              onTap: isLocked
                                  ? () {
                                Get.snackbar(
                                  'Month Locked',
                                  '$monthName $year is in the future and not accessible yet.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(12),
                                  duration: const Duration(seconds: 2),
                                );
                              }
                                  : () {
                                expenseCtrl.setSelectedYear(year);
                                expenseCtrl.setSelectedMonth(month);

                                Get.to(
                                      () => const DashboardScreen(),
                                  transition: Transition.rightToLeftWithFade,
                                  duration: const Duration(milliseconds: 300),
                                );
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? theme.disabledColor.withOpacity(0.04)
                                      : (isCurrentMonth
                                      ? theme.colorScheme.primary.withOpacity(0.08)
                                      : theme.cardTheme.color ?? theme.colorScheme.surface),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isCurrentMonth
                                        ? theme.colorScheme.primary
                                        : (isLocked
                                        ? Colors.transparent
                                        : theme.dividerColor.withOpacity(0.12)),
                                    width: isCurrentMonth ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          monthName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isLocked
                                                ? theme.disabledColor
                                                : theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        if (isLocked)
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 16,
                                            color: theme.disabledColor.withOpacity(0.6),
                                          )
                                        else if (isCurrentMonth)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (!isLocked) ...[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('In:',
                                                  style: TextStyle(
                                                      fontSize: 10, color: theme.disabledColor)),
                                              Text(
                                                'Rs. ${income.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Out:',
                                                  style: TextStyle(
                                                      fontSize: 10, color: theme.disabledColor)),
                                              Text(
                                                'Rs. ${expense.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.disabledColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 8, thickness: 0.5),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Bal:',
                                                  style: TextStyle(
                                                      fontSize: 11, fontWeight: FontWeight.bold)),
                                              Text(
                                                'Rs. ${balance.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: balance >= 0
                                                      ? theme.colorScheme.primary
                                                      : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ] else ...[
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'Locked',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.disabledColor.withOpacity(0.5),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _yearBarScrollController.dispose();
    super.dispose();
  }
}