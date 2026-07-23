import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:daily_expense_tracker/models/category_model.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';

class ExpenseController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final _uuid = const Uuid();

  // Reactive variables
  final categories = <CategoryModel>[].obs;
  final expenses = <ExpenseModel>[].obs;
  final monthlyIncomes = <String, double>{}.obs;
  final selectedDate = DateTime.now().obs;
  final isLoadingData = false.obs;

  @override
  void onInit() {
    super.onInit();
    categories.assignAll(_getDefaultCategories());

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadData();
      } else {
        _clearLocalData();
      }
    });

    if (_auth.currentUser != null) {
      loadData();
    }
  }

  void _clearLocalData() {
    expenses.clear();
    monthlyIncomes.clear();
    categories.assignAll(_getDefaultCategories());
  }

  String? get currentUid => _auth.currentUser?.uid;

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Reverse lookup of _getMonthName, used when parsing the "income" node
  // nested under expenses/{uid}/{year}/{monthName}.
  int? _monthNumberFromName(String name) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final idx = months.indexOf(name);
    return idx == -1 ? null : idx + 1;
  }

  // --- SECURE LOAD DATA FROM NESTED HIERARCHY ---
  // Structure read/written:
  //   expenses/{uid}/{year}/{monthName}/income/{amount, createdAt, updatedAt}
  //   expenses/{uid}/{year}/{monthName}/transactions/{txId}/{...}
  //
  // For backward compatibility with data saved before this structure existed,
  // this also reads (and gracefully migrates) the old locations:
  //   incomes/{uid}/{year}-{month}            (old flat income value)
  //   expenses/{uid}/{year}/{monthName}/{txId} (old transactions directly under month)
  Future<void> loadData() async {
    // Thora sa delay taake Firebase session fully stabilize ho jaye
    await Future.delayed(const Duration(milliseconds: 300));

    final uid = currentUid;
    if (uid == null) {
      _clearLocalData();
      return;
    }

    isLoadingData.value = true;
    try {
      // NOTE: Each fetch below has its OWN try/catch so a failure in one
      // can't skip the others — which previously caused data to be stuck at
      // 0 after logging back in even though it was safely stored in Firebase.

      // 1. Fetch legacy top-level incomes (pre-refactor location), used only
      //    as a fallback for months not yet migrated to the new structure.
      Map<String, double> legacyIncomes = {};
      try {
        final legacyIncomeSnapshot = await _dbRef.child('incomes').child(uid).get();
        if (legacyIncomeSnapshot.exists && legacyIncomeSnapshot.value != null) {
          final Map<dynamic, dynamic> incomeData = legacyIncomeSnapshot.value as Map<dynamic, dynamic>;
          incomeData.forEach((key, val) {
            if (val is num) {
              legacyIncomes[key.toString()] = val.toDouble();
            }
          });
        }
      } catch (e) {
        print('Error loading legacy incomes: $e');
      }

      // 2. Fetch Categories from categories/{uid}
      try {
        final catSnapshot = await _dbRef.child('categories').child(uid).get();
        if (catSnapshot.exists && catSnapshot.value != null) {
          final Map<dynamic, dynamic> catData = catSnapshot.value as Map<dynamic, dynamic>;
          List<CategoryModel> loadedCats = [];
          catData.forEach((key, val) {
            if (val is Map) {
              final map = Map<String, dynamic>.from(val);
              loadedCats.add(CategoryModel(
                id: map['id'] ?? key.toString(),
                name: map['name'] ?? '',
                iconName: map['iconName'] ?? 'category',
                colorHex: map['colorHex'] ?? 0xFF10B981,
              ));
            }
          });
          if (loadedCats.isNotEmpty) {
            categories.assignAll(loadedCats);
          }
        } else {
          final defaultCats = _getDefaultCategories();
          categories.assignAll(defaultCats);
          for (var cat in defaultCats) {
            await _dbRef.child('categories').child(uid).child(cat.id).set({
              'id': cat.id,
              'name': cat.name,
              'iconName': cat.iconName,
              'colorHex': cat.colorHex,
            });
          }
        }
      } catch (e) {
        print('Error loading categories: $e');
      }

      // 3. Fetch Income + Transactions from expenses/{uid}/{year}/{monthName}
      Map<String, double> newStructureIncomes = {};
      List<ExpenseModel> loadedExpenses = [];
      final Map<String, dynamic> legacyTransactionMigrations = {};

      try {
        final expSnapshot = await _dbRef.child('expenses').child(uid).get();
        if (expSnapshot.exists && expSnapshot.value != null && expSnapshot.value is Map) {
          final Map<dynamic, dynamic> yearsData = expSnapshot.value as Map<dynamic, dynamic>;

          yearsData.forEach((yearKey, monthsMap) {
            if (monthsMap is! Map) return;
            final yearStr = yearKey.toString();

            monthsMap.forEach((monthKey, monthData) {
              if (monthData is! Map) return;
              final monthStr = monthKey.toString();
              final monthMap = Map<dynamic, dynamic>.from(monthData);

              // ---- Income (new structure: .../{monthName}/income/amount) ----
              final incomeNode = monthMap['income'];
              if (incomeNode is Map) {
                final incomeMap = Map<String, dynamic>.from(incomeNode);
                final amt = incomeMap['amount'];
                final monthNum = _monthNumberFromName(monthStr);
                final yearNum = int.tryParse(yearStr);
                if (amt is num && monthNum != null && yearNum != null) {
                  newStructureIncomes[_getMonthKey(monthNum, yearNum)] = amt.toDouble();
                }
              }

              // ---- Transactions (new structure: .../{monthName}/transactions/{txId}) ----
              final txNode = monthMap['transactions'];
              if (txNode is Map) {
                Map<dynamic, dynamic>.from(txNode).forEach((txId, val) {
                  if (val is Map) {
                    try {
                      final map = Map<String, dynamic>.from(val);
                      loadedExpenses.add(ExpenseModel(
                        id: map['id'] ?? txId.toString(),
                        title: map['title'] ?? '',
                        amount: (map['amount'] as num).toDouble(),
                        categoryId: map['categoryId'] ?? '',
                        note: map['note'] ?? '',
                        date: DateTime.parse(map['date']),
                      ));
                    } catch (e) {
                      print('Error parsing transaction ID $txId: $e');
                    }
                  }
                });
              }

              // ---- Legacy transactions stored directly under the month
              //      (pre-refactor format, before "income"/"transactions" split) ----
              monthMap.forEach((childKey, childVal) {
                if (childKey == 'income' || childKey == 'transactions') return;
                if (childVal is! Map) return;
                final map = Map<String, dynamic>.from(childVal);
                if (map['amount'] == null || map['date'] == null) return;
                try {
                  final txId = (map['id'] ?? childKey).toString();
                  loadedExpenses.add(ExpenseModel(
                    id: txId,
                    title: map['title'] ?? '',
                    amount: (map['amount'] as num).toDouble(),
                    categoryId: map['categoryId'] ?? '',
                    note: map['note'] ?? '',
                    date: DateTime.parse(map['date']),
                  ));
                  // Queue migration: move this record into the new
                  // "transactions" node and remove the legacy entry.
                  legacyTransactionMigrations['$yearStr/$monthStr/transactions/$txId'] = map;
                  legacyTransactionMigrations['$yearStr/$monthStr/$childKey'] = null;
                } catch (e) {
                  print('Error migrating legacy transaction $childKey: $e');
                }
              });
            });
          });
        }
      } catch (e) {
        print('Error loading expenses/income: $e');
      }

      // Merge income: new-structure entries win; legacy top-level incomes
      // fill in any months not yet migrated.
      final mergedIncomes = <String, double>{...legacyIncomes, ...newStructureIncomes};
      if (mergedIncomes.isNotEmpty) {
        monthlyIncomes.assignAll(mergedIncomes);
      } else {
        monthlyIncomes.clear();
      }
      expenses.assignAll(loadedExpenses);

      // Fire-and-forget: migrate any legacy-format data discovered above into
      // the new income/transactions structure so future loads read purely
      // from it. Failures here don't affect what's already shown on screen.
      if (legacyTransactionMigrations.isNotEmpty) {
        _dbRef.child('expenses').child(uid).update(legacyTransactionMigrations).catchError((e) {
          print('Error migrating legacy transactions to new structure: $e');
        });
      }
      if (legacyIncomes.isNotEmpty) {
        _migrateLegacyIncomes(uid, legacyIncomes, newStructureIncomes).catchError((e) {
          print('Error migrating legacy incomes to new structure: $e');
        });
      }
    } finally {
      isLoadingData.value = false;
    }
  }

  /// Moves any legacy incomes/{uid}/{year}-{month} entries into the new
  /// expenses/{uid}/{year}/{monthName}/income node, and removes the old
  /// entries once migrated (or if already superseded by new-structure data).
  Future<void> _migrateLegacyIncomes(
      String uid,
      Map<String, double> legacyIncomes,
      Map<String, double> newStructureIncomes,
      ) async {
    final now = DateTime.now().toIso8601String();
    final Map<String, dynamic> updates = {};

    legacyIncomes.forEach((key, amount) {
      // Already present in the new structure — just clean up the old entry.
      if (newStructureIncomes.containsKey(key)) {
        updates['incomes/$uid/$key'] = null;
        return;
      }

      final parts = key.split('-');
      if (parts.length != 2) return;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year == null || month == null) return;

      final monthName = _getMonthName(month);
      updates['expenses/$uid/$year/$monthName/income'] = {
        'amount': amount,
        'createdAt': now,
        'updatedAt': now,
      };
      updates['incomes/$uid/$key'] = null;
    });

    if (updates.isNotEmpty) {
      await _dbRef.update(updates);
    }
  }

  /// Public helper so other parts of the app (e.g. right after a successful
  /// login) can explicitly force a fresh reload of this user's data from
  /// Firebase, instead of only relying on the authStateChanges listener.
  Future<void> refreshUserData() => loadData();

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

  String _getMonthKey(int month, int year) {
    final m = month.toString().padLeft(2, '0');
    return '$year-$m';
  }

  double getIncomeForMonth(int month, int year) {
    final key = _getMonthKey(month, year);
    return monthlyIncomes[key] ?? 0.0;
  }

  double get currentIncome {
    return getIncomeForMonth(selectedDate.value.month, selectedDate.value.year);
  }

  RxDouble get income => currentIncome.obs;

  // --- SYNCHRONIZED INCOME UPDATE ---
  Future<void> setIncomeForMonth(double val, {int? month, int? year}) async {
    final uid = currentUid;
    if (uid == null) return;

    final targetMonth = month ?? selectedDate.value.month;
    final targetYear = year ?? selectedDate.value.year;
    final key = _getMonthKey(targetMonth, targetYear);

    // 1. Update local UI immediately and trigger reactive recalculations
    monthlyIncomes[key] = val;
    monthlyIncomes.refresh();

    final yearStr = targetYear.toString();
    final monthStr = _getMonthName(targetMonth);
    final incomeRef = _dbRef.child('expenses').child(uid).child(yearStr).child(monthStr).child('income');
    final now = DateTime.now().toIso8601String();

    // Preserve the original createdAt if this month's income already exists.
    String createdAt = now;
    try {
      final existing = await incomeRef.child('createdAt').get();
      if (existing.exists && existing.value != null) {
        createdAt = existing.value.toString();
      }
    } catch (e) {
      print('Error checking existing income createdAt: $e');
    }

    // 2. Save updated income immediately to Firebase under specific month node
    await incomeRef.set({
      'amount': val,
      'createdAt': createdAt,
      'updatedAt': now,
    });
  }

  Future<void> setIncome(double val) async {
    await setIncomeForMonth(val);
  }

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

  Future<void> addCategory(String name, String iconName, Color color) async {
    final uid = currentUid;
    if (uid == null) return;

    final newCat = CategoryModel(
      id: 'cat_${_uuid.v4()}',
      name: name,
      iconName: iconName,
      colorHex: color.value,
    );
    categories.add(newCat);
    categories.refresh();

    await _dbRef.child('categories').child(uid).child(newCat.id).set({
      'id': newCat.id,
      'name': newCat.name,
      'iconName': newCat.iconName,
      'colorHex': newCat.colorHex,
    });
  }

  // --- ADD EXPENSE WITH EXACT DATE & TIME ---
  Future<void> addExpense({
    required String title,
    required double amount,
    required String categoryId,
    required String note,
    required DateTime date,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    final now = DateTime.now();
    final DateTime finalDate = DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );

    final newExp = ExpenseModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      categoryId: categoryId,
      note: note,
      date: finalDate,
    );

    expenses.add(newExp);
    expenses.refresh();

    String yearStr = finalDate.year.toString();
    String monthStr = _getMonthName(finalDate.month);

    await _dbRef.child('expenses').child(uid).child(yearStr).child(monthStr).child('transactions').child(newExp.id).set({
      'id': newExp.id,
      'title': newExp.title,
      'amount': newExp.amount,
      'categoryId': newExp.categoryId,
      'note': newExp.note,
      'date': newExp.date.toIso8601String(),
    });
  }

  // --- EDIT TRANSACTION WITH REALTIME SYNC ---
  Future<void> editExpense(ExpenseModel updated) async {
    final uid = currentUid;
    if (uid == null) return;

    final index = expenses.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      final oldExpense = expenses[index];

      // Remove from old location in Firebase if date/month changed
      String oldYear = oldExpense.date.year.toString();
      String oldMonth = _getMonthName(oldExpense.date.month);
      await _dbRef.child('expenses').child(uid).child(oldYear).child(oldMonth).child('transactions').child(updated.id).remove();

      // Update local UI immediately and trigger recalculations
      expenses[index] = updated;
      expenses.refresh();

      // Save updated transaction to new location in Firebase immediately
      String newYear = updated.date.year.toString();
      String newMonth = _getMonthName(updated.date.month);

      await _dbRef.child('expenses').child(uid).child(newYear).child(newMonth).child('transactions').child(updated.id).set({
        'id': updated.id,
        'title': updated.title,
        'amount': updated.amount,
        'categoryId': updated.categoryId,
        'note': updated.note,
        'date': updated.date.toIso8601String(),
      });
    }
  }

  // --- DELETE TRANSACTION WITH REALTIME SYNC & AUTO RECALCULATION ---
  Future<void> deleteExpense(String id) async {
    final uid = currentUid;
    if (uid == null) return;

    final expenseToDelete = expenses.firstWhereOrNull((e) => e.id == id);
    if (expenseToDelete != null) {
      String yearStr = expenseToDelete.date.year.toString();
      String monthStr = _getMonthName(expenseToDelete.date.month);

      // Remove from local UI immediately (triggers automatic UI recalculation)
      expenses.removeWhere((e) => e.id == id);
      expenses.refresh();

      // Remove record from Firebase Realtime Database immediately
      await _dbRef.child('expenses').child(uid).child(yearStr).child(monthStr).child('transactions').child(id).remove();
    }
  }

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