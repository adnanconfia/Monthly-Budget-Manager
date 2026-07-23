import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Fetch current authenticated user details dynamically
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? 'user@example.com';
    final String rawName = user?.displayName ?? (userEmail.isNotEmpty ? userEmail.split('@').first : 'Valued User');
    final String userName = rawName.isNotEmpty ? rawName[0].toUpperCase() + rawName.substring(1) : 'Valued User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Space', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card Info
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Dynamic Current Month Income Display
                          Obx(() {
                            final now = DateTime.now();
                            final currentMonthIncome = controller.getIncomeForMonth(now.month, now.year);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Active Income: Rs. ${currentMonthIncome.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Controls
            Text('General Configuration', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 8),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Obx(() => ListTile(
                    leading: Icon(themeController.isDarkMode.value ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: theme.colorScheme.primary),
                    title: const Text('Dark Mode Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Switch.adaptive(
                      value: themeController.isDarkMode.value,
                      onChanged: (_) => themeController.toggleTheme(),
                    ),
                  )),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.currency_exchange_rounded, color: theme.colorScheme.primary),
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

            // Developer Brand Info Card
            Card(
              elevation: 0,
              color: theme.colorScheme.primary.withOpacity(0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Premium Edition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Daily Expense Tracker v1.0.0', style: TextStyle(fontSize: 11)),
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