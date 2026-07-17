import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/models/category_model.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';
import 'package:daily_expense_tracker/views/widgets/add_category_dialog.dart';
import 'package:daily_expense_tracker/views/widgets/icon_mapper.dart';

class AddExpenseSheet extends StatefulWidget {
  final ExpenseModel? existingExpense;
  const AddExpenseSheet({super.key, this.existingExpense});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final controller = Get.find<ExpenseController>();
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  CategoryModel? selectedCategory;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final exp = widget.existingExpense!;
      titleController.text = exp.title;
      amountController.text = exp.amount.toString();
      noteController.text = exp.note;
      selectedDate = exp.date;
      selectedCategory = controller.categories.firstWhereOrNull((c) => c.id == exp.categoryId);
    } else if (controller.categories.isNotEmpty) {
      selectedCategory = controller.categories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingExpense != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.disabledColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEdit ? 'Edit Transaction Details' : 'Record New Expense',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Expense Title',
                  prefixIcon: const Icon(Icons.edit_note),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter descriptive name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (Rs.)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter valid amount';
                  final numVal = double.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'Must be a positive value';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Obx(() {
                return DropdownButtonFormField<CategoryModel>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Expense Category',
                    filled: true,
                    fillColor: theme.cardTheme.color,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    ...controller.categories.map((cat) {
                      return DropdownMenuItem<CategoryModel>(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(getIconFromString(cat.iconName), color: cat.color),
                            const SizedBox(width: 10),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (cat) {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddCategoryDialog(),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Custom Category', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Memo / Note (Optional)',
                  prefixIcon: const Icon(Icons.description_outlined),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    if (selectedCategory == null) {
                      Get.snackbar('Error', 'Please select a valid category');
                      return;
                    }
                    if (isEdit) {
                      controller.editExpense(ExpenseModel(
                        id: widget.existingExpense!.id,
                        title: titleController.text.trim(),
                        amount: double.parse(amountController.text),
                        categoryId: selectedCategory!.id,
                        note: noteController.text.trim(),
                        date: selectedDate,
                      ));
                    } else {
                      controller.addExpense(
                        title: titleController.text.trim(),
                        amount: double.parse(amountController.text),
                        categoryId: selectedCategory!.id,
                        note: noteController.text.trim(),
                        date: selectedDate,
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  isEdit ? 'Save Changes' : 'Record Transaction',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}