import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:daily_expense_tracker/controllers/expense_controller.dart';

class IncomeInputDialog extends StatelessWidget {
  final bool isFirstTime;
  const IncomeInputDialog({super.key, this.isFirstTime = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    final textController = TextEditingController(
      text: isFirstTime ? '' : controller.income.value.toStringAsFixed(0),
    );

    return AlertDialog(
      title: Text(isFirstTime ? 'Welcome! Set Monthly Income' : 'Update Monthly Income'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please enter your total active monthly income to establish your balance dashboard.'),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Income Amount (Rs.)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_wallet),
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
          onPressed: () {
            final val = double.tryParse(textController.text);
            if (val != null && val > 0) {
              controller.setIncome(val);
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