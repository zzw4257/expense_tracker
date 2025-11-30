import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/settings.dart';
import '../services/ai_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  late AppSettings _settings;
  AiService? _aiService;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppSettings get settings => _settings;
  AiService? get aiService => _aiService;

  ExpenseProvider() {
    _initSettings();
  }

  void _initSettings() {
    // 从环境变量加载API Key
    final geminiKey = dotenv.env['GEMINI_API_KEY'];
    final openaiKey = dotenv.env['OPENAI_API_KEY'];
    
    _settings = AppSettings(
      geminiApiKey: geminiKey,
      openaiApiKey: openaiKey,
      aiProvider: AiProvider.gemini, // 默认Gemini
    );
    
    _aiService = AiService(_settings);
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    _aiService = AiService(_settings);
    
    // 保存设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings', jsonEncode(_settings.toJson()));
    
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('settings');
    if (data != null) {
      final json = jsonDecode(data);
      // 合并环境变量中的API Key
      json['geminiApiKey'] ??= dotenv.env['GEMINI_API_KEY'];
      json['openaiApiKey'] ??= dotenv.env['OPENAI_API_KEY'];
      _settings = AppSettings.fromJson(json);
    } else {
      _initSettings();
    }
    _aiService = AiService(_settings);
    notifyListeners();
  }

  // AI摘要
  Future<String?> summarizeText(String text) async {
    return await _aiService?.summarize(text);
  }

  // AI提取结构化数据
  Future<Map<String, dynamic>?> extractData(String text) async {
    return await _aiService?.extractStructuredData(text);
  }

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
