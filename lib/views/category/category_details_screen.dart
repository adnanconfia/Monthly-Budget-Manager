import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/models/category_model.dart';
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
        title: Row(
          children: [
            Icon(getIconFromString(category.iconName), color: category.color),
            const SizedBox(width: 8),
            Text(category.name),
          ],
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final catExpenses = controller.expenses.where((e) => e.categoryId == category.id).toList();

        if (catExpenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  'No Expenses in ${category.name}',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: catExpenses.length,
          itemBuilder: (context, index) {
            final exp = catExpenses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exp.note.isNotEmpty) Text(exp.note),
                    Text(DateFormat('dd-MM-yyyy').format(exp.date)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rs. ${exp.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: category.color,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => AddExpenseSheet(existingExpense: exp),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Delete Transaction",
                          middleText: "Are you sure you want to remove this record?",
                          textConfirm: "Delete",
                          textCancel: "Cancel",
                          confirmTextColor: Colors.white,
                          onConfirm: () {
                            controller.deleteExpense(exp.id);
                            Get.back();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}