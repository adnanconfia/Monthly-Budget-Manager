import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/controllers/theme_controller.dart';
import 'package:daily_expense_tracker/services/storage_service.dart';
import 'package:daily_expense_tracker/views/splash/splash_screen.dart';

void main() async {
  // 1. Native binding ko instant trigger karein taake visual layout draw ho sake
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Heavy storage initialization ko parallel run karein bina main execution block kiye
  _initializeServicesAndControllers();

  runApp(const DailyExpenseTrackerApp());
}

/// Dynamic background initialization to optimize app startup speed
void _initializeServicesAndControllers() async {
  await GetStorage.init();

  // Storage and Controllers inject in the background
  Get.put(StorageService());
  Get.put(ThemeController());
  Get.put(ExpenseController());
}

class DailyExpenseTrackerApp extends StatelessWidget {
  const DailyExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Fallback/Placeholder theme jab tak controllers memory mein instantiate ho rahe hon
    const Color emeraldGreen = Color(0xFF10B981);
    const Color navyDarkBg = Color(0xFF0F172A);

    return GetMaterialApp(
      title: 'Daily Expense Tracker',
      debugShowCheckedModeBanner: false,

      // Fallback UI definitions setup till controllers load completely
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: emeraldGreen,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navyDarkBg,
        primaryColor: emeraldGreen,
      ),
      themeMode: ThemeMode.system,

      home: const SplashScreen(),
    );
  }
}