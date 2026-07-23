import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:daily_expense_tracker/controllers/auth_controller.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';
import 'package:daily_expense_tracker/controllers/theme_controller.dart';
import 'package:daily_expense_tracker/services/storage_service.dart';
import 'package:daily_expense_tracker/views/splash/splash_screen.dart';

void main() async {
  // 1. Native binding ko instant trigger karein taake visual layout draw ho sake
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase initialize karna lazmi hai taake Auth & Realtime Database crash na karein
  await Firebase.initializeApp();

  // 3. Heavy storage initialization aur controllers ko background mein run karein
  await _initializeServicesAndControllers();

  runApp(const DailyExpenseTrackerApp());
}

/// Dynamic background initialization to optimize app startup speed
Future<void> _initializeServicesAndControllers() async {
  await GetStorage.init();

  // Storage and Controllers injection
  Get.put(StorageService(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(ExpenseController(), permanent: true);
}

class DailyExpenseTrackerApp extends StatelessWidget {
  const DailyExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color emeraldGreen = Color(0xFF10B981);
    const Color navyDarkBg = Color(0xFF0F172A);

    return GetMaterialApp(
      title: 'Daily Expense Tracker',
      debugShowCheckedModeBanner: false,

      // Theme definitions setup
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: emeraldGreen,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navyDarkBg,
        primaryColor: emeraldGreen,
      ),
      themeMode: ThemeMode.system,

      home: const SplashScreen(),
    );
  }
}