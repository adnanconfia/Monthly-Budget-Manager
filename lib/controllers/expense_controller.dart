import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:daily_expense_tracker/models/category_model.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';
import 'package:daily_expense_tracker/services/storage_service.dart';

class ExpenseController extends GetxController {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  // Reactive variables
  final income = 0.0.obs;
  final categories = <CategoryModel>[].obs;
  final expenses = <ExpenseModel>[].obs;

  // Dynamic Month Selection State
  final selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() {
    income.value = _storage.getIncome();

    final loadedCats = _storage.getCategories();
    if (loadedCats.isEmpty) {
      categories.assignAll(_getDefaultCategories());
      _storage.saveCategories(categories);
    } else {
      categories.assignAll(loadedCats);
    }

    expenses.assignAll(_storage.getExpenses());
  }

  List<CategoryModel> _getDefaultCategories() {
    return [
      CategoryModel(id: 'cat_food', name: 'Food', iconName: 'restaurant', colorHex: 0xFFED5565),
      CategoryModel(id: 'cat_travel', name: 'Travel', iconName: 'directions_car', colorHex: 0xFF4FC1E9),
      CategoryModel(id: 'cat_shopping', name: 'Shopping', iconName: 'shopping_bag', colorHex: 0xFFAC92EC),
      CategoryModel(id: 'cat_electricity', name: 'Electricity', iconName: 'bolt', colorHex: 0xFFFFCE54),
      CategoryModel(id: 'cat_water', name: 'Water', iconName: 'water_drop', colorHex: 0xFF4A89DC),
      CategoryModel(id: 'cat_internet', name: 'Internet', iconName: 'wifi', colorHex: 0xFF3BAFDA),
      CategoryModel(id: 'cat_fuel', name: 'Fuel', iconName: 'local_gas_station', colorHex: 0xFFFC6E51),
      CategoryModel(id: 'cat_entertainment', name: 'Entertainment', iconName: 'sports_esports', colorHex: 0xFFEC87C0),
      CategoryModel(id: 'cat_medical', name: 'Medical', iconName: 'local_hospital', colorHex: 0xFF8CC152),
      CategoryModel(id: 'cat_education', name: 'Education', iconName: 'school', colorHex: 0xFF37BC9B),
    ];
  }

  void setIncome(double val) {
    income.value = val;
    _storage.saveIncome(val);
  }

  void changeMonth(DateTime newDate) {
    selectedDate.value = newDate;
    expenses.refresh();
  }

  void addCategory(String name, String iconName, Color color) {
    final newCat = CategoryModel(
      id: 'cat_${_uuid.v4()}',
      name: name,
      iconName: iconName,
      colorHex: color.value,
    );
    categories.add(newCat);
    categories.refresh();
    _storage.saveCategories(categories);
  }

  // --- SAFE WRITE OPERATIONS ---

  void addExpense({
    required String title,
    required double amount,
    required String categoryId,
    required String note,
    required DateTime date,
  }) {
    final newExp = ExpenseModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      categoryId: categoryId,
      note: note,
      date: date,
    );

    expenses.add(newExp);

    // `.refresh()` ke sath pure list layout reassigning stream ko refresh kiya hai
    expenses.refresh();

    _storage.saveExpenses(expenses);
  }

  void editExpense(ExpenseModel updated) {
    final index = expenses.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      expenses[index] = updated;
      expenses.refresh();
      _storage.saveExpenses(expenses);
    }
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    expenses.refresh();
    _storage.saveExpenses(expenses);
  }

  // --- Dynamic Month filtering properties ---

  List<ExpenseModel> get monthlyExpenses {
    return expenses.where((exp) {
      return exp.date.month == selectedDate.value.month &&
          exp.date.year == selectedDate.value.year;
    }).toList();
  }

  double get totalMonthlyExpenses {
    return monthlyExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get remainingMonthlySavings {
    return income.value - totalMonthlyExpenses;
  }

  // --- SMART CALCULATION LOGIC (COMPLETELY ROBUST MATCHING) ---

  double getCategorySpend(String categoryId) {
    // Current category find karein taake uska standard name string mil sake
    final currentCat = categories.firstWhereOrNull((c) => c.id == categoryId);
    final String catName = currentCat?.name.toLowerCase().trim() ?? "";
    final String normalizedTargetId = categoryId.toLowerCase().trim();

    return monthlyExpenses.where((e) {
      final String savedIdOrName = e.categoryId.toLowerCase().trim();

      // Safety Check: Agar input raw text name ho ya default static structure ID ho, dono filter pakar le
      return savedIdOrName == normalizedTargetId || savedIdOrName == catName;
    }).fold(0.0, (sum, item) => sum + item.amount);
  }

  // FIXED: Function corrected to calculate percentage relative to total income pool
  double getCategoryPercentage(String categoryId) {
    final double totalIncomePool = income.value;

    // Safety check for fallback to prevent division by zero
    if (totalIncomePool <= 0) return 0.0;

    // Calculation based on Total Income instead of Total Expense
    return (getCategorySpend(categoryId) / totalIncomePool) * 100;
  }

  // --- General Calculations Fallbacks ---
  double get totalExpenses => expenses.fold(0.0, (sum, item) => sum + item.amount);
  double get remainingSavings => income.value - totalExpenses;
  int get transactionCount => expenses.length;

  double get totalPercentSpent {
    if (income.value <= 0) return 0.0;
    return (totalMonthlyExpenses / income.value) * 100;
  }

  String get highestExpenseCategory {
    if (expenses.isEmpty) return "None";
    Map<String, double> catSum = {};
    for (var exp in expenses) {
      catSum[exp.categoryId] = (catSum[exp.categoryId] ?? 0.0) + exp.amount;
    }
    String topId = "";
    double maxVal = -1.0;
    catSum.forEach((key, val) {
      if (val > maxVal) {
        maxVal = val;
        topId = key;
      }
    });
    final cat = categories.firstWhereOrNull((c) => c.id == topId);
    return cat != null ? "${cat.name} (Rs. ${maxVal.toStringAsFixed(0)})" : "None";
  }

  Map<String, dynamic> get highestSpendingCategory {
    final mExpenses = monthlyExpenses;
    if (mExpenses.isEmpty) {
      return {'name': 'None', 'color': Colors.grey};
    }

    Map<String, double> catSum = {};
    for (var exp in mExpenses) {
      catSum[exp.categoryId] = (catSum[exp.categoryId] ?? 0.0) + exp.amount;
    }

    String topId = "";
    double maxVal = -1.0;
    catSum.forEach((key, val) {
      if (val > maxVal) {
        maxVal = val;
        topId = key;
      }
    });

    final cat = categories.firstWhereOrNull((c) => c.id == topId);
    if (cat != null) {
      return {
        'name': cat.name,
        'color': cat.color,
      };
    }
    return {'name': 'None', 'color': Colors.grey};
  }
}