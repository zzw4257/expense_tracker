import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalAmount => _expenses.fold(0, (sum, e) => sum + e.amount);
  double get pendingAmount =>
      _expenses.where((e) => e.status == ExpenseStatus.pending).fold(0, (sum, e) => sum + e.amount);
  double get approvedAmount =>
      _expenses.where((e) => e.status == ExpenseStatus.approved).fold(0, (sum, e) => sum + e.amount);

  Map<ExpenseCategory, double> get categoryBreakdown {
    final map = <ExpenseCategory, double>{};
    for (final expense in _expenses) {
      map[expense.category] = (map[expense.category] ?? 0) + expense.amount;
    }
    return map;
  }

  Map<String, double> get monthlyBreakdown {
    final map = <String, double>{};
    for (final expense in _expenses) {
      final key = DateFormat('yyyy-MM').format(expense.date);
      map[key] = (map[key] ?? 0) + expense.amount;
    }
    return map;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('expenses');
      if (data != null) {
        final list = jsonDecode(data) as List;
        _expenses = list.map((e) => Expense.fromJson(e)).toList();
        _expenses.sort((a, b) => b.date.compareTo(a.date));
      }
      _error = null;
    } catch (e) {
      _error = '加载数据失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', jsonEncode(_expenses.map((e) => e.toJson()).toList()));
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.insert(0, expense);
    await _saveExpenses();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      await _saveExpenses();
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _saveExpenses();
    notifyListeners();
  }

  bool validateTaxNumber(String taxNumber) {
    final regex = RegExp(r'^[0-9A-HJ-NPQRTUWXY]{2}\d{6}[0-9A-HJ-NPQRTUWXY]{10}$');
    return regex.hasMatch(taxNumber.toUpperCase());
  }

  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('标题,金额,日期,类别,状态,备注');
    for (final e in _expenses) {
      buffer.writeln(
        '${e.title},${e.amount},${DateFormat('yyyy-MM-dd').format(e.date)},${e.category.label},${e.status.label},${e.description ?? ""}',
      );
    }
    return buffer.toString();
  }
}
