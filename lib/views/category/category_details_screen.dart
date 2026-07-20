import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/models/category_model.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';
import 'package:daily_expense_tracker/views/widgets/add_expense_sheet.dart';
import 'package:daily_expense_tracker/views/widgets/icon_mapper.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final CategoryModel category;

  const CategoryDetailsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final activeDate = controller.selectedDate.value;
          final formattedMonthYear = DateFormat('MMMM yyyy').format(activeDate);
          return Column(
            children: [
              Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                formattedMonthYear,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          // 🎯 ACTIVE MONTH & YEAR FILTERING
          final activeDate = controller.selectedDate.value;
          final normalizedCatId = category.id.toLowerCase().trim();
          final normalizedCatName = category.name.toLowerCase().trim();

          // Filter expenses to show ONLY items matching:
          // 1. Current Selected Month
          // 2. Current Selected Year
          // 3. Current Category (ID or Name)
          final filteredCategoryExpenses = controller.expenses.where((exp) {
            final isSameMonth = exp.date.month == activeDate.month;
            final isSameYear = exp.date.year == activeDate.year;

            final savedIdOrName = exp.categoryId.toLowerCase().trim();
            final isSameCategory = savedIdOrName == normalizedCatId ||
                savedIdOrName == normalizedCatName;

            return isSameMonth && isSameYear && isSameCategory;
          }).toList();

          // Calculate category spend for the selected month/year
          final totalCategorySpend = filteredCategoryExpenses.fold(
            0.0,
                (sum, item) => sum + item.amount,
          );

          return Column(
            children: [
              // 1. Month-Isolated Summary Card for this Category
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: category.color.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        getIconFromString(category.iconName),
                        color: category.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${category.name} Outlay',
                            style: TextStyle(
                              color: theme.disabledColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${totalCategorySpend.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Month-Isolated Transaction List
              Expanded(
                child: filteredCategoryExpenses.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: theme.disabledColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No ${category.name} expenses recorded for\n${DateFormat('MMMM yyyy').format(activeDate)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.disabledColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCategoryExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredCategoryExpenses[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          expense.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy').format(expense.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.disabledColor,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rs. ${expense.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFFF43F5E),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => AddExpenseSheet(
                                    existingExpense: expense,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                controller.deleteExpense(expense.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}