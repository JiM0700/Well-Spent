import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/forecast_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Expense> _expenses = [];
  double _monthlyBudget = 1000.0;
  bool _isLoading = false;
  ExpenseCategory? _selectedCategoryFilter;

  List<Expense> get expenses => _selectedCategoryFilter == null
      ? _expenses
      : _expenses.where((e) => e.category == _selectedCategoryFilter).toList();

  List<Expense> get allExpenses => _expenses;
  double get monthlyBudget => _monthlyBudget;
  bool get isLoading => _isLoading;
  ExpenseCategory? get selectedCategoryFilter => _selectedCategoryFilter;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _expenses = await _dbService.getAllExpenses();
      _monthlyBudget = await _dbService.getMonthlyBudget();
    } catch (e) {
      if (kDebugMode) print('Error loading DB data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterByCategory(ExpenseCategory? category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    final id = await _dbService.insertExpense(expense);
    _expenses.insert(0, expense.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbService.updateExpense(expense);
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _expenses[idx] = expense;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id) async {
    await _dbService.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> updateMonthlyBudget(double newBudget) async {
    await _dbService.setMonthlyBudget(newBudget);
    _monthlyBudget = newBudget;
    notifyListeners();
  }

  // --- CALCULATED METRICS ---

  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.date.year == now.year && e.date.month == now.month;
    }).toList();
  }

  double get currentMonthTotal {
    return currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get todayTotal {
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day;
    }).fold(0.0, (sum, e) => sum + e.amount);
  }

  MonthlyForecast get forecast {
    return ForecastService.calculateForecast(
      currentMonthExpenses: currentMonthExpenses,
      monthlyBudget: _monthlyBudget,
      now: DateTime.now(),
    );
  }

  Map<ExpenseCategory, double> get categoryBreakdown {
    final Map<ExpenseCategory, double> totals = {};
    for (var category in ExpenseCategory.values) {
      totals[category] = 0.0;
    }
    for (var expense in currentMonthExpenses) {
      totals[expense.category] = (totals[expense.category] ?? 0.0) + expense.amount;
    }
    return totals;
  }
}
