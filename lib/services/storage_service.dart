import 'dart:convert';
import 'package:get_storage/get_storage.dart';

import 'package:daily_expense_tracker/models/category_model.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';

class StorageService {
  final _box = GetStorage();

  static const String _keyIncome = 'monthly_income';
  static const String _keyCategories = 'categories';
  static const String _keyExpenses = 'expenses';
  static const String _keyDarkMode = 'dark_mode';

  double getIncome() {
    return _box.read<double>(_keyIncome) ?? 0.0;
  }

  void saveIncome(double income) {
    _box.write(_keyIncome, income);
  }

  List<CategoryModel> getCategories() {
    final raw = _box.read<String>(_keyCategories);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((item) => CategoryModel.fromJson(item)).toList();
  }

  void saveCategories(List<CategoryModel> categories) {
    final raw = jsonEncode(categories.map((c) => c.toJson()).toList());
    _box.write(_keyCategories, raw);
  }

  List<ExpenseModel> getExpenses() {
    final raw = _box.read<String>(_keyExpenses);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((item) => ExpenseModel.fromJson(item)).toList();
  }

  void saveExpenses(List<ExpenseModel> expenses) {
    final raw = jsonEncode(expenses.map((e) => e.toJson()).toList());
    _box.write(_keyExpenses, raw);
  }

  bool isDarkMode() {
    return _box.read<bool>(_keyDarkMode) ?? false;
  }

  void saveThemeMode(bool isDark) {
    _box.write(_keyDarkMode, isDark);
  }
}