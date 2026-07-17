import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';
import 'package:daily_expense_tracker/views/widgets/add_expense_sheet.dart';
import 'package:daily_expense_tracker/views/widgets/icon_mapper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final controller = Get.find<ExpenseController>();
  final searchController = TextEditingController();

  String searchQuery = '';
  String? selectedCategoryId;
  String selectedSort = 'date_desc';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Logs'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Transactions...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val.toLowerCase();
                        });
                      },
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String?>(
                            value: selectedCategoryId,
                            isExpanded: true,
                            hint: const Text('All Categories'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Categories')),
                              ...controller.categories.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedCategoryId = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedSort,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'date_desc', child: Text('Date: Newest')),
                              DropdownMenuItem(value: 'date_asc', child: Text('Date: Oldest')),
                              DropdownMenuItem(value: 'amount_desc', child: Text('Amount: High')),
                              DropdownMenuItem(value: 'amount_asc', child: Text('Amount: Low')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedSort = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              List<ExpenseModel> filteredList = controller.expenses.where((exp) {
                final matchesSearch = exp.title.toLowerCase().contains(searchQuery) ||
                    exp.note.toLowerCase().contains(searchQuery);
                final matchesCategory = selectedCategoryId == null || exp.categoryId == selectedCategoryId;
                return matchesSearch && matchesCategory;
              }).toList();

              if (selectedSort == 'date_desc') {
                filteredList.sort((a, b) => b.date.compareTo(a.date));
              } else if (selectedSort == 'date_asc') {
                filteredList.sort((a, b) => a.date.compareTo(b.date));
              } else if (selectedSort == 'amount_desc') {
                filteredList.sort((a, b) => b.amount.compareTo(a.amount));
              } else if (selectedSort == 'amount_asc') {
                filteredList.sort((a, b) => a.amount.compareTo(b.amount));
              }

              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text('No matching records found', style: TextStyle(color: theme.disabledColor)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final exp = filteredList[index];
                  final cat = controller.categories.firstWhereOrNull((c) => c.id == exp.categoryId);
                  final catColor = cat?.color ?? Colors.grey;

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: catColor.withOpacity(0.15),
                        child: Icon(getIconFromString(cat?.iconName ?? 'category'), color: catColor),
                      ),
                      title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${DateFormat('dd MMM yyyy').format(exp.date)} | ${cat?.name ?? 'Uncategorized'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rs. ${exp.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => AddExpenseSheet(existingExpense: exp),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              Get.defaultDialog(
                                title: "Confirm Delete",
                                middleText: "Do you really want to remove this expense?",
                                textConfirm: "Yes, Delete",
                                textCancel: "Cancel",
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
          ),
        ],
      ),
    );
  }
}