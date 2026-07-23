import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/views/dashboard/dashboard_screen.dart';
// Apni login screen ka path yahan import kar lein (agar file ka naam alag ho toh change kar lein)
import 'package:daily_expense_tracker/views/auth/login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => LoginScreen());
      });
    } else {
      // Automatically scroll to current year and its active month on startup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentYear = DateTime.now().year;
        final yearIndex = currentYear - startYear;
        if (yearIndex >= 0) {
          _scrollToYear(currentYear, yearIndex);
        }
      });
    }

    // Listen to main scroll to update active year chip dynamically
    _mainScrollController.addListener(_onMainScroll);
  }

  void _onMainScroll() {
    if (!_mainScrollController.hasClients) return;
    final offset = _mainScrollController.offset;
    final currentNow = DateTime.now();
    final totalYearsCount = (currentNow.year - startYear) + 1;

    final context = Get.context;
    double rowHeight = 150.0;
    if (context != null) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = (screenWidth - 32 - 12) / 2;
      final itemHeight = itemWidth / 1.25;
      rowHeight = itemHeight + 12;
    }
    const headerHeight = 55.0;
    final yearSectionHeight = headerHeight + (6 * rowHeight) + 8;

    final estimatedYearIndex = (offset / yearSectionHeight).floor().clamp(0, totalYearsCount - 1);
    final calculatedYear = startYear + estimatedYearIndex;

    if (calculatedYear != _selectedYearHeader) {
      setState(() {
        _selectedYearHeader = calculatedYear;
      });
      final yearIndex = calculatedYear - startYear;
      final double targetChipOffset = yearIndex * 80.0;
      if (_yearBarScrollController.hasClients) {
        _yearBarScrollController.animateTo(
          targetChipOffset.clamp(0.0, _yearBarScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }

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
      final context = Get.context;
      double rowHeight = 150.0;
      if (context != null) {
        final screenWidth = MediaQuery.of(context).size.width;
        final itemWidth = (screenWidth - 32 - 12) / 2;
        final itemHeight = itemWidth / 1.25;
        rowHeight = itemHeight + 12;
      }
      const headerHeight = 55.0;
      final yearSectionHeight = headerHeight + (6 * rowHeight) + 8;

      double targetOffset = 0.0;
      if (year == DateTime.now().year) {
        // Current year: scroll to active month
        final targetMonth = DateTime.now().month;
        final monthRowIndex = (targetMonth - 1) ~/ 2;
        targetOffset = (yearIndex * yearSectionHeight) + headerHeight + (monthRowIndex * rowHeight);
      } else {
        // Past years (like 2025): scroll to the very top of that year's section header
        targetOffset = yearIndex * yearSectionHeight;
      }

      if (_mainScrollController.hasClients) {
        _mainScrollController.animateTo(
          targetOffset.clamp(0.0, _mainScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }

    if (_yearBarScrollController.hasClients) {
      final double targetChipOffset = index * 80.0;
      _yearBarScrollController.animateTo(
        targetChipOffset.clamp(0.0, _yearBarScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Logout Confirmation Dialog ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog
              await FirebaseAuth.instance.signOut(); // Sign out from Firebase
              Get.offAll(() =>  LoginScreen()); // Direct navigation to Login Screen
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseCtrl = Get.find<ExpenseController>();
    final currentNow = DateTime.now();

    final totalYearsCount = (currentNow.year - startYear) + 1;
    final yearsList = List.generate(totalYearsCount, (i) => startYear + i);

    // Gate the Dashboard behind the data-loading state so it never briefly
    // (or permanently) shows default 0 values while the user's saved
    // income/expenses are still being fetched from Firebase after login.
    return Obx(() {
      if (expenseCtrl.isLoadingData.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Financial Timeline',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(vertical: 2.0),
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
                        visualDensity: VisualDensity.compact,
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
              Expanded(
                child: ListView.builder(
                  controller: _mainScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 12.0),
                  itemCount: totalYearsCount,
                  itemBuilder: (context, yearIndex) {
                    final year = startYear + yearIndex;
                    final isCurrentYear = year == currentNow.year;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 10.0, left: 4.0, right: 4.0),
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
    });
  }

  @override
  void dispose() {
    _mainScrollController.removeListener(_onMainScroll);
    _mainScrollController.dispose();
    _yearBarScrollController.dispose();
    super.dispose();
  }
}