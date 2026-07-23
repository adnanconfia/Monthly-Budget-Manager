import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';

import 'package:daily_expense_tracker/models/category_model.dart';
import 'package:daily_expense_tracker/models/expense_model.dart';

class StorageService {
  final _box = GetStorage();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --- Local Settings (Theme Mode) ---
  bool isDarkMode() {
    return _box.read<bool>('dark_mode') ?? false;
  }

  void saveThemeMode(bool isDark) {
    _box.write('dark_mode', isDark);
  }

  // --- Firebase Realtime Database: Monthly Incomes ---
  Future<Map<String, double>> getMonthlyIncomes() async {
    if (_uid == null) return {};
    try {
      final snapshot = await _dbRef.child('users').child(_uid!).child('monthly_incomes').get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> rawMap = snapshot.value as Map<dynamic, dynamic>;
        return rawMap.map((key, value) => MapEntry(key.toString(), (value as num).toDouble()));
      }
    } catch (e) {
      print('Error loading monthly incomes: $e');
    }
    return {};
  }

  Future<void> saveMonthlyIncomes(Map<String, double> incomeMap) async {
    if (_uid == null) return;
    try {
      await _dbRef.child('users').child(_uid!).child('monthly_incomes').set(incomeMap);
    } catch (e) {
      print('Error saving monthly incomes: $e');
    }
  }

  // --- Firebase Realtime Database: Categories ---
  Future<List<CategoryModel>> getCategories() async {
    if (_uid == null) return [];
    try {
      final snapshot = await _dbRef.child('users').child(_uid!).child('categories').get();
      if (snapshot.exists && snapshot.value != null) {
        final List<dynamic> rawList = snapshot.value as List<dynamic>;
        return rawList.map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
    return [];
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    if (_uid == null) return;
    try {
      final listData = categories.map((c) => c.toJson()).toList();
      await _dbRef.child('users').child(_uid!).child('categories').set(listData);
    } catch (e) {
      print('Error saving categories: $e');
    }
  }

  // --- Firebase Realtime Database: Expenses ---
  Future<List<ExpenseModel>> getExpenses() async {
    if (_uid == null) return [];
    try {
      final snapshot = await _dbRef.child('expenses').child(_uid!).get();
      if (snapshot.exists && snapshot.value != null) {
        if (snapshot.value is List) {
          final List<dynamic> rawList = snapshot.value as List<dynamic>;
          return rawList
              .where((item) => item != null)
              .map((item) => ExpenseModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        } else if (snapshot.value is Map) {
          final Map<dynamic, dynamic> rawMap = snapshot.value as Map<dynamic, dynamic>;
          List<ExpenseModel> loaded = [];
          rawMap.forEach((key, value) {
            if (value != null) {
              loaded.add(ExpenseModel.fromJson(Map<String, dynamic>.from(value)));
            }
          });
          return loaded;
        }
      }
    } catch (e) {
      print('Error loading expenses: $e');
    }
    return [];
  }

  Future<void> saveExpenses(List<ExpenseModel> expenses) async {
    if (_uid == null) return;
    try {
      final mapData = <String, dynamic>{};
      for (var exp in expenses) {
        mapData[exp.id] = exp.toJson();
      }
      await _dbRef.child('expenses').child(_uid!).set(mapData);
    } catch (e) {
      print('Error saving expenses: $e');
    }
  }
}