import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:daily_expense_tracker/controllers/expense_controller.dart';

class IncomeInputDialog extends StatelessWidget {
  final bool isFirstTime;
  const IncomeInputDialog({super.key, this.isFirstTime = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    final activeDate = controller.selectedDate.value;
    final monthYearStr = DateFormat('MMMM yyyy').format(activeDate);

    // Fetch existing income for the currently selected month
    final currentMonthIncome = controller.getIncomeForMonth(
      activeDate.month,
      activeDate.year,
    );

    final textController = TextEditingController(
      text: isFirstTime
          ? ''
          : (currentMonthIncome > 0 ? currentMonthIncome.toStringAsFixed(0) : ''),
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isFirstTime
            ? 'Welcome! Set Income for $monthYearStr'
            : 'Update Income for $monthYearStr',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please enter your total active monthly income for $monthYearStr to establish your balance dashboard.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Income Amount (Rs.)',
              prefixText: 'Rs. ',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (!isFirstTime)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            final val = double.tryParse(textController.text.trim());
            if (val != null && val >= 0) {
              controller.setIncomeForMonth(
                val,
                month: activeDate.month,
                year: activeDate.year,
              );
              Navigator.pop(context);
            } else {
              Get.snackbar(
                'Invalid Amount',
                'Please enter a valid positive income number.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.redAccent,
                colorText: Colors.white,
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}