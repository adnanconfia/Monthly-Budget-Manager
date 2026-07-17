import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/views/widgets/icon_mapper.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';

class DetailedMonthlyExpensePage extends StatefulWidget {
  const DetailedMonthlyExpensePage({super.key});

  @override
  State<DetailedMonthlyExpensePage> createState() => _DetailedMonthlyExpensePageState();
}

class _DetailedMonthlyExpensePageState extends State<DetailedMonthlyExpensePage> {
  final ExpenseController controller = Get.find<ExpenseController>();
  final TextEditingController searchController = TextEditingController();

  String query = "";
  String selectedCategoryId = "All";
  String sortBy = "Date"; // Options: Date, Amount

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          '${DateFormat('MMMM yyyy').format(controller.selectedDate.value)} Registry',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        )),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Sleek Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: (val) => setState(() => query = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search expense...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: theme.disabledColor.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          // 2. Horizontal Filter Bar
          _buildFilterBar(theme),

          // 3. Main Filtered List View
          Expanded(
            child: Obx(() {
              var list = controller.monthlyExpenses.where((e) {
                final matchQuery = e.title.toLowerCase().contains(query);
                final matchCategory = selectedCategoryId == "All" || e.categoryId == selectedCategoryId;
                return matchQuery && matchCategory;
              }).toList();

              // Sort algorithms execution
              if (sortBy == "Date") {
                list.sort((a, b) => b.date.compareTo(a.date));
              } else {
                list.sort((a, b) => b.amount.compareTo(a.amount));
              }

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 40, color: theme.disabledColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text('No matching records', style: TextStyle(color: theme.disabledColor, fontSize: 13)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final expense = list[index];
                  final category = controller.categories.firstWhere(
                        (c) => c.id == expense.categoryId,
                    orElse: () => controller.categories.first,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.02)),
                    ),
                    child: ListTile(
                      onTap: () => _showTransactionDetailsBottomSheet(expense, category, theme),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: category.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(getIconFromString(category.iconName), color: category.color, size: 18),
                      ),
                      title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(DateFormat('dd MMM hh:mm a').format(expense.date), style: TextStyle(fontSize: 10, color: theme.disabledColor)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '- Rs. ${expense.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip("All", "All", theme),
          ...controller.categories.map((c) => _buildFilterChip(c.id, c.name, theme)),
          const VerticalDivider(width: 20, thickness: 1),
          GestureDetector(
            onTap: () {
              setState(() {
                sortBy = sortBy == "Date" ? "Amount" : "Date";
              });
            },
            child: Chip(
              label: Text("Sort: $sortBy", style: const TextStyle(fontSize: 11)),
              avatar: const Icon(Icons.swap_vert, size: 14),
              backgroundColor: theme.disabledColor.withValues(alpha: 0.06),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, ThemeData theme) {
    final isSelected = selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => selectedCategoryId = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.disabledColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.disabledColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // Transaction Details Sheet
  void _showTransactionDetailsBottomSheet(ExpenseModel expense, dynamic category, ThemeData theme) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.disabledColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: category.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(getIconFromString(category.iconName), color: category.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(category.name, style: TextStyle(fontSize: 12, color: theme.disabledColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow("Amount Charged", "Rs. ${expense.amount.toStringAsFixed(2)}", theme, isBold: true),
            _buildDetailRow("Transaction Date", DateFormat('dd MMMM yyyy, hh:mm a').format(expense.date), theme),
            _buildDetailRow("Reference ID", expense.id, theme),
            _buildDetailRow("Notes/Tags", expense.note.isEmpty ? "None" : expense.note, theme),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    label: const Text("Delete", style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Get.back();
                      _confirmDeletion(expense);
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String val, ThemeData theme, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: theme.disabledColor, fontWeight: FontWeight.bold)),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _confirmDeletion(ExpenseModel expense) {
    final theme = Theme.of(context);
    Get.defaultDialog(
        title: "Delete Entry",
        middleText: "Are you sure you want to completely erase this transaction entry from local databases?",
        textConfirm: "Delete",
        textCancel: "Cancel",
        confirmTextColor: Colors.white,
        buttonColor: theme.colorScheme.error,
        onConfirm: () {
          controller.deleteExpense(expense.id);
          Get.back();
        }
    );
  }
}