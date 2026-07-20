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
  final categories = <CategoryModel>[].obs;
  final expenses = <ExpenseModel>[].obs;

  // Independent Monthly Incomes Storage (Key: "YYYY-MM")
  final monthlyIncomes = <String, double>{}.obs;

  // Dynamic Month Selection State
  final selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() {
    // Load monthly incomes map
    final loadedIncomes = _storage.getMonthlyIncomes();
    if (loadedIncomes != null) {
      monthlyIncomes.assignAll(loadedIncomes);
    }

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

  // --- Month Key Helper ---
  String _getMonthKey(int month, int year) {
    final m = month.toString().padLeft(2, '0');
    return '$year-$m';
  }

  // --- Isolated Income Management ---
  double getIncomeForMonth(int month, int year) {
    final key = _getMonthKey(month, year);
    return monthlyIncomes[key] ?? 0.0;
  }

  double get currentIncome {
    return getIncomeForMonth(selectedDate.value.month, selectedDate.value.year);
  }

  // Backward compatibility getter for screens referencing income.value
  RxDouble get income => currentIncome.obs;

  void setIncomeForMonth(double val, {int? month, int? year}) {
    final targetMonth = month ?? selectedDate.value.month;
    final targetYear = year ?? selectedDate.value.year;
    final key = _getMonthKey(targetMonth, targetYear);

    monthlyIncomes[key] = val;
    monthlyIncomes.refresh();
    _storage.saveMonthlyIncomes(monthlyIncomes);
  }

  void setIncome(double val) {
    setIncomeForMonth(val);
  }

  // --- Date Timeline Selection ---
  void changeMonth(DateTime newDate) {
    selectedDate.value = newDate;
    expenses.refresh();
    monthlyIncomes.refresh();
  }

  void setSelectedYear(int year) {
    selectedDate.value = DateTime(year, selectedDate.value.month, 1);
    expenses.refresh();
    monthlyIncomes.refresh();
  }

  void setSelectedMonth(int month) {
    selectedDate.value = DateTime(selectedDate.value.year, month, 1);
    expenses.refresh();
    monthlyIncomes.refresh();
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

  double getMonthlyExpensesSum(int month, int year) {
    return expenses
        .where((exp) => exp.date.month == month && exp.date.year == year)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get remainingMonthlySavings {
    return currentIncome - totalMonthlyExpenses;
  }

  // --- SMART CALCULATION LOGIC ---

  double getCategorySpend(String categoryId) {
    final currentCat = categories.firstWhereOrNull((c) => c.id == categoryId);
    final String catName = currentCat?.name.toLowerCase().trim() ?? "";
    final String normalizedTargetId = categoryId.toLowerCase().trim();

    return monthlyExpenses.where((e) {
      final String savedIdOrName = e.categoryId.toLowerCase().trim();
      return savedIdOrName == normalizedTargetId || savedIdOrName == catName;
    }).fold(0.0, (sum, item) => sum + item.amount);
  }

  double getCategoryPercentage(String categoryId) {
    final double totalIncomePool = currentIncome;
    if (totalIncomePool <= 0) return 0.0;
    return (getCategorySpend(categoryId) / totalIncomePool) * 100;
  }

  // --- General Calculations Fallbacks ---
  double get totalExpenses => totalMonthlyExpenses;
  double get remainingSavings => remainingMonthlySavings;
  int get transactionCount => monthlyExpenses.length;

  double get totalPercentSpent {
    if (currentIncome <= 0) return 0.0;
    return (totalMonthlyExpenses / currentIncome) * 100;
  }

  String get highestExpenseCategory {
    final mExpenses = monthlyExpenses;
    if (mExpenses.isEmpty) return "None";
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