import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';
import 'package:daily_expense_tracker/views/widgets/add_expense_sheet.dart';
import 'package:daily_expense_tracker/views/widgets/icon_mapper.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // 📖 READ-ONLY TRANSACTION DETAILS DIALOG
  void _showTransactionDetailsDialog(
      BuildContext context, ExpenseModel expense, ExpenseController controller) {
    final theme = Theme.of(context);
    final category = controller.categories.firstWhereOrNull(
          (c) => c.id == expense.categoryId,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Icon Header
            CircleAvatar(
              radius: 28,
              backgroundColor: (category?.color ?? theme.colorScheme.primary).withOpacity(0.15),
              child: Icon(
                getIconFromString(category?.iconName ?? 'category'),
                color: category?.color ?? theme.colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              expense.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Category Name
            Text(
              category?.name ?? 'Uncategorized',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.disabledColor,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Amount Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount Spent:',
                  style: TextStyle(fontSize: 13, color: theme.disabledColor),
                ),
                Text(
                  'Rs. ${expense.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Date Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date:',
                  style: TextStyle(fontSize: 13, color: theme.disabledColor),
                ),
                Text(
                  DateFormat('dd MMMM yyyy').format(expense.date),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Note / Description Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Note / Description:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.disabledColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.disabledColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              ),
              child: Text(
                expense.note.isNotEmpty ? expense.note : 'No description added.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: expense.note.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                  color: expense.note.isNotEmpty ? null : theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 🎡 SCROLLABLE WHEEL PICKER FOR MONTH & YEAR
  Future<void> _showScrollableMonthYearPicker(BuildContext context, ExpenseController controller) async {
    final activeDate = controller.selectedDate.value;

    int selectedYear = activeDate.year;
    int selectedMonth = activeDate.month;

    final yearsList = List.generate(11, (index) => 2020 + index); // 2020 to 2030
    final monthsList = List.generate(12, (index) => index + 1);

    final FixedExtentScrollController yearScrollController = FixedExtentScrollController(
      initialItem: yearsList.indexOf(selectedYear) != -1 ? yearsList.indexOf(selectedYear) : 5,
    );
    final FixedExtentScrollController monthScrollController = FixedExtentScrollController(
      initialItem: selectedMonth - 1,
    );

    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final theme = Theme.of(ctx);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Select Month & Year',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    // 📜 MONTHS WHEEL
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Month',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: monthScrollController,
                              itemExtent: 40,
                              perspective: 0.005,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                selectedMonth = monthsList[index];
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: monthsList.length,
                                builder: (context, index) {
                                  final mDate = DateTime(2026, monthsList[index]);
                                  final mName = DateFormat('MMMM').format(mDate);
                                  return Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      mName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 100,
                      color: theme.dividerColor.withOpacity(0.3),
                    ),

                    // 📜 YEARS WHEEL
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Year',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: yearScrollController,
                              itemExtent: 40,
                              perspective: 0.005,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                selectedYear = yearsList[index];
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: yearsList.length,
                                builder: (context, index) {
                                  return Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${yearsList[index]}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 12, left: 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      controller.selectedDate.value = DateTime(selectedYear, selectedMonth, 1);
                      Navigator.pop(ctx);
                    },
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
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
                'Transaction History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 2),
              // CLICKABLE MONTH & YEAR SUBTITLE
              InkWell(
                onTap: () => _showScrollableMonthYearPicker(context, controller),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthYearStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        final activeDate = controller.selectedDate.value;

        // MONTH & YEAR AUTOMATIC FILTER
        final monthlyExpenses = controller.expenses.where((expense) {
          return expense.date.year == activeDate.year &&
              expense.date.month == activeDate.month;
        }).toList();

        monthlyExpenses.sort((a, b) => b.date.compareTo(a.date));

        if (monthlyExpenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.disabledColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions found for ${DateFormat('MMMM yyyy').format(activeDate)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          itemCount: monthlyExpenses.length,
          itemBuilder: (context, index) {
            final expense = monthlyExpenses[index];
            final category = controller.categories.firstWhereOrNull(
                  (c) => c.id == expense.categoryId,
            );

            return Dismissible(
              key: Key(expense.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: const Text('Are you sure you want to delete this expense entry?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                controller.deleteExpense(expense.id);
                Get.snackbar(
                  'Deleted',
                  '${expense.title} has been removed',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  // 🌟 TAP TO OPEN READ-ONLY DETAILS
                  onTap: () => _showTransactionDetailsDialog(context, expense, controller),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: (category?.color ?? theme.colorScheme.primary).withOpacity(0.15),
                    child: Icon(
                      getIconFromString(category?.iconName ?? 'category'),
                      color: category?.color ?? theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    expense.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        DateFormat('dd MMM, yyyy').format(expense.date),
                        style: TextStyle(fontSize: 12, color: theme.disabledColor),
                      ),
                      if (expense.note.isNotEmpty) ...[
                        Text(' • ', style: TextStyle(color: theme.disabledColor)),
                        Expanded(
                          child: Text(
                            expense.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: theme.disabledColor),
                          ),
                        ),
                      ]
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '- Rs. ${expense.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddExpenseSheet(existingExpense: expense),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}