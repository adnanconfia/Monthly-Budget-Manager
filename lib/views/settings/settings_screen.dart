import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/controllers/theme_controller.dart';
import 'package:daily_expense_tracker/views/widgets/income_input_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    final themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Space', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card Info
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(Icons.account_circle, color: theme.colorScheme.primary, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Valued User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                            'Budget Cap: Rs. ${controller.income.value.toStringAsFixed(0)}',
                            style: TextStyle(color: theme.disabledColor, fontSize: 12),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Controls
            Text('General configuration', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  Obx(() => ListTile(
                    leading: Icon(themeController.isDarkMode.value ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                    title: const Text('Dark Mode Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Switch.adaptive(
                      value: themeController.isDarkMode.value,
                      onChanged: (_) => themeController.toggleTheme(),
                    ),
                  )),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange_rounded),
                    title: const Text('Edit Budget Baseline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const IncomeInputDialog(isFirstTime: false),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Developer Brand info card
            Card(
              color: theme.colorScheme.primary.withOpacity(0.04),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Premium Edition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Daily Expense Tracker v1.0.0', style: TextStyle(fontSize: 11,)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}