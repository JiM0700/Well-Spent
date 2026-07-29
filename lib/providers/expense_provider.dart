import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/forecast_service.dart';

class PeriodRange {
  final DateTime startDate;
  final DateTime endDate;
  final double targetBudget;
  final String label;
  final String modeName;

  PeriodRange({
    required this.startDate,
    required this.endDate,
    required this.targetBudget,
    required this.label,
    required this.modeName,
  });
}

class SummaryWindow {
  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime previousStart;
  final DateTime previousEnd;

  SummaryWindow({
    required this.currentStart,
    required this.currentEnd,
    required this.previousStart,
    required this.previousEnd,
  });
}

class SummaryStats {
  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime previousStart;
  final DateTime previousEnd;
  final double total;
  final double previousTotal;
  final double? differencePct;
  final String topCategory;
  final String label;

  SummaryStats({
    required this.currentStart,
    required this.currentEnd,
    required this.previousStart,
    required this.previousEnd,
    required this.total,
    required this.previousTotal,
    required this.differencePct,
    required this.topCategory,
    required this.label,
  });
}

class ChartDataPoint {
  final String label;
  final double amount;
  final DateTime date;

  ChartDataPoint({
    required this.label,
    required this.amount,
    required this.date,
  });
}

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Expense> _expenses = [];
  double _monthlyBudget = 1000.0;
  bool _isLoading = false;
  ExpenseCategory? _selectedCategoryFilter;
  int _cycleStartDay = 1;
  double _baseMonthlyIncome = 0.0;
  int _payDay = 1;
  bool _summaryEnabled = true;
  String _summaryPeriod = 'daily';
  String _viewMode = 'monthly';
  String _chartMode = 'daywise';

  List<Expense> get expenses => _selectedCategoryFilter == null
      ? _expenses
      : _expenses.where((e) => e.category == _selectedCategoryFilter).toList();

  List<Expense> get allExpenses => _expenses;
  double get monthlyBudget => _monthlyBudget;
  bool get isLoading => _isLoading;
  ExpenseCategory? get selectedCategoryFilter => _selectedCategoryFilter;
  int get cycleStartDay => _cycleStartDay;
  double get baseMonthlyIncome => _baseMonthlyIncome;
  int get payDay => _payDay;
  bool get summaryEnabled => _summaryEnabled;
  String get summaryPeriod => _summaryPeriod;
  String get viewMode => _viewMode;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _expenses = await _dbService.getAllExpenses();
      _monthlyBudget = await _dbService.getMonthlyBudget();
      _cycleStartDay = await _dbService.getCycleStartDay();
      _baseMonthlyIncome = await _dbService.getBaseMonthlyIncome();
      _payDay = await _dbService.getPayDay();
      _summaryEnabled = await _dbService.getSummaryEnabled();
      _summaryPeriod = await _dbService.getSummaryPeriod();
      _viewMode = await _dbService.getViewMode();
      _chartMode = await _dbService.getChartMode();
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

  Future<void> updateCycleStartDay(int day) async {
    await _dbService.setCycleStartDay(day);
    _cycleStartDay = day;
    notifyListeners();
  }

  Future<void> updateBaseMonthlyIncome(double income) async {
    await _dbService.setBaseMonthlyIncome(income);
    _baseMonthlyIncome = income;
    notifyListeners();
  }

  Future<void> updatePayDay(int day) async {
    await _dbService.setPayDay(day);
    _payDay = day;
    notifyListeners();
  }

  Future<void> updateSummaryEnabled(bool enabled) async {
    await _dbService.setSummaryEnabled(enabled);
    _summaryEnabled = enabled;
    notifyListeners();
  }

  Future<void> updateSummaryPeriod(String period) async {
    await _dbService.setSummaryPeriod(period);
    _summaryPeriod = period;
    notifyListeners();
  }

  String get chartMode => _chartMode;

  Future<void> updateViewMode(String mode) async {
    await _dbService.setViewMode(mode);
    _viewMode = mode;
    notifyListeners();
  }

  Future<void> updateChartMode(String mode) async {
    await _dbService.setChartMode(mode);
    _chartMode = mode;
    notifyListeners();
  }

  DateTime _normalizeDay(int year, int month, int day) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, min(day, daysInMonth));
  }

  SummaryWindow _buildSummaryWindow() {
    final now = DateTime.now();
    if (_summaryPeriod == 'daily') {
      final currentStart = DateTime(now.year, now.month, now.day);
      final currentEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final previousStart = currentStart.subtract(const Duration(days: 1));
      final previousEnd = DateTime(previousStart.year, previousStart.month, previousStart.day, 23, 59, 59, 999);
      return SummaryWindow(
        currentStart: currentStart,
        currentEnd: currentEnd,
        previousStart: previousStart,
        previousEnd: previousEnd,
      );
    }

    if (_summaryPeriod == 'weekly') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final currentStart = DateTime(monday.year, monday.month, monday.day);
      final currentEnd = DateTime(currentStart.year, currentStart.month, currentStart.day + 6, 23, 59, 59, 999);
      final previousStart = currentStart.subtract(const Duration(days: 7));
      final previousEnd = DateTime(previousStart.year, previousStart.month, previousStart.day + 6, 23, 59, 59, 999);
      return SummaryWindow(
        currentStart: currentStart,
        currentEnd: currentEnd,
        previousStart: previousStart,
        previousEnd: previousEnd,
      );
    }

    final period = currentPeriodRange;
    final currentStart = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
    final currentEndRaw = DateTime(
      now.isBefore(period.endDate) ? now.year : period.endDate.year,
      now.isBefore(period.endDate) ? now.month : period.endDate.month,
      now.isBefore(period.endDate) ? now.day : period.endDate.day,
    );
    final currentEnd = DateTime(currentEndRaw.year, currentEndRaw.month, currentEndRaw.day, 23, 59, 59, 999);
    final windowDays = currentEnd.difference(currentStart).inDays + 1;
    final previousEnd = currentStart.subtract(const Duration(milliseconds: 1));
    final previousStart = DateTime(
      previousEnd.year,
      previousEnd.month,
      previousEnd.day,
    ).subtract(Duration(days: windowDays - 1));
    return SummaryWindow(
      currentStart: currentStart,
      currentEnd: currentEnd,
      previousStart: previousStart,
      previousEnd: DateTime(previousEnd.year, previousEnd.month, previousEnd.day, 23, 59, 59, 999),
    );
  }

  SummaryStats get summaryStats {
    final window = _buildSummaryWindow();
    final currentEntries = _expenses.where((e) {
      return e.isExpense && !e.date.isBefore(window.currentStart) && !e.date.isAfter(window.currentEnd);
    }).toList();

    final previousTotal = _expenses.where((e) {
      return e.isExpense && !e.date.isBefore(window.previousStart) && !e.date.isAfter(window.previousEnd);
    }).fold(0.0, (sum, entry) => sum + entry.amount);

    final total = currentEntries.fold(0.0, (sum, entry) => sum + entry.amount);

    final categoryTotals = <ExpenseCategory, double>{};
    for (final category in ExpenseCategory.values) {
      categoryTotals[category] = 0.0;
    }
    for (final entry in currentEntries) {
      categoryTotals[entry.category] = (categoryTotals[entry.category] ?? 0.0) + entry.amount;
    }

    final topCategory = categoryTotals.entries
            .where((entry) => entry.value > 0)
            .toList()
            .fold<ExpenseCategory?>(null, (best, entry) {
      if (best == null) return entry.key;
      return entry.value > (categoryTotals[best] ?? 0) ? entry.key : best;
    });

    final topCategoryLabel = topCategory != null ? topCategory.displayName : 'No spending yet';
    final differencePct = previousTotal == 0
        ? (total > 0 ? null : 0.0)
        : ((total - previousTotal) / previousTotal) * 100.0;

    return SummaryStats(
      currentStart: window.currentStart,
      currentEnd: window.currentEnd,
      previousStart: window.previousStart,
      previousEnd: window.previousEnd,
      total: total,
      previousTotal: previousTotal,
      differencePct: differencePct,
      topCategory: topCategoryLabel,
      label: _summaryPeriod == 'daily'
          ? 'Today'
          : _summaryPeriod == 'weekly'
              ? 'This Week'
              : 'This Cycle',
    );
  }

  String get summaryPeriodLabel {
    switch (_summaryPeriod) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Daily';
    }
  }

  DateTime _getPaydayDate(int year, int month, int day) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, min(day, daysInMonth));
  }

  DateTime get currentPayday {
    final now = DateTime.now();
    final thisPayday = _getPaydayDate(now.year, now.month, _payDay);
    return now.isBefore(thisPayday)
        ? _getPaydayDate(now.year, now.month - 1, _payDay)
        : thisPayday;
  }

  DateTime get nextPayday {
    final now = DateTime.now();
    final thisPayday = _getPaydayDate(now.year, now.month, _payDay);
    return now.isBefore(thisPayday)
        ? thisPayday
        : _getPaydayDate(now.year, now.month + 1, _payDay);
  }

  int get daysUntilNextPayday {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final diff = nextPayday.difference(end).inDays;
    return max(1, diff);
  }

  double get incomeSinceLastPayday {
    final last = currentPayday;
    final now = DateTime.now();
    final incomeTotal = _expenses.where((e) {
      return e.isIncome && !e.date.isBefore(last) && !e.date.isAfter(now);
    }).fold(0.0, (sum, entry) => sum + entry.amount);
    return incomeTotal + (_baseMonthlyIncome > 0 ? _baseMonthlyIncome : 0);
  }

  double get expensesSinceLastPayday {
    final last = currentPayday;
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.isExpense && !e.date.isBefore(last) && !e.date.isAfter(now);
    }).fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double get safeBurnRate {
    final remainingIncome = incomeSinceLastPayday - expensesSinceLastPayday;
    return max(0.0, remainingIncome) / daysUntilNextPayday;
  }

  double get remainingIncome => max(0.0, incomeSinceLastPayday - expensesSinceLastPayday);

  List<ChartDataPoint> get chartData {
    return _chartMode == 'monthwise' ? _monthwisePoints() : _daywisePoints();
  }

  List<ChartDataPoint> _daywisePoints() {
    final range = currentPeriodRange;
    final points = <ChartDataPoint>[];
    var cursor = DateTime(range.startDate.year, range.startDate.month, range.startDate.day);
    final end = DateTime(range.endDate.year, range.endDate.month, range.endDate.day);

    while (!cursor.isAfter(end)) {
      final dayEnd = DateTime(cursor.year, cursor.month, cursor.day, 23, 59, 59, 999);
      final amount = _expenses.where((e) {
        return e.isExpense && !e.date.isBefore(cursor) && !e.date.isAfter(dayEnd);
      }).fold(0.0, (sum, entry) => sum + entry.amount);
      points.add(ChartDataPoint(
        label: DateFormat('d MMM').format(cursor),
        amount: amount,
        date: cursor,
      ));
      cursor = cursor.add(const Duration(days: 1));
    }
    return points;
  }

  List<ChartDataPoint> _monthwisePoints() {
    final now = DateTime.now();
    final points = <ChartDataPoint>[];
    for (var offset = 11; offset >= 0; offset--) {
      final monthStart = DateTime(now.year, now.month - offset, 1);
      final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
      final amount = _expenses.where((e) {
        return e.isExpense && !e.date.isBefore(monthStart) && e.date.isBefore(nextMonth);
      }).fold(0.0, (sum, entry) => sum + entry.amount);
      points.add(ChartDataPoint(
        label: DateFormat('MMM').format(monthStart),
        amount: amount,
        date: monthStart,
      ));
    }
    return points;
  }

  String get chartModeLabel {
    return _chartMode == 'monthwise' ? 'Monthwise' : 'Daywise';
  }

  String get summaryRangeLabel {
    final stats = summaryStats;
    return '${DateFormat('d MMM').format(stats.currentStart)} – ${DateFormat('d MMM').format(stats.currentEnd)}';
  }

  String get summaryDifferenceLabel {
    final stats = summaryStats;
    if (stats.differencePct == null) return 'New spending vs previous period';
    if (stats.differencePct == 0) return '— 0% vs previous period';
    final up = stats.differencePct! > 0;
    return '${up ? '↑' : '↓'} ${stats.differencePct!.abs().toStringAsFixed(0)}% vs previous period';
  }

  String get summaryTopCategoryLabel => summaryStats.topCategory;

  PeriodRange get currentPeriodRange {
    final now = DateTime.now();
    if (_viewMode == 'weekly') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(monday.year, monday.month, monday.day);
      final end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
      return PeriodRange(
        startDate: start,
        endDate: end,
        targetBudget: _monthlyBudget / 4.33,
        label: 'Weekly',
        modeName: 'Weekly',
      );
    }

    if (_viewMode == 'yearly') {
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
      return PeriodRange(
        startDate: start,
        endDate: end,
        targetBudget: _monthlyBudget * 12,
        label: 'Yearly',
        modeName: 'Yearly',
      );
    }

    // Monthly cycle mode
    final DateTime start;
    if (_cycleStartDay == 1 || now.day >= _cycleStartDay) {
      start = _normalizeDay(now.year, now.month, _cycleStartDay);
    } else {
      final prior = DateTime(now.year, now.month - 1);
      start = _normalizeDay(prior.year, prior.month, _cycleStartDay);
    }
    final next = _normalizeDay(start.year, start.month + 1, _cycleStartDay);
    final end = next.subtract(const Duration(milliseconds: 1));

    return PeriodRange(
      startDate: start,
      endDate: end,
      targetBudget: _monthlyBudget,
      label: 'Monthly Cycle',
      modeName: 'Monthly',
    );
  }

  List<Expense> get currentPeriodExpenses {
    final range = currentPeriodRange;
    return _expenses.where((e) {
      return e.isExpense &&
          !e.date.isBefore(range.startDate) &&
          !e.date.isAfter(range.endDate);
    }).toList();
  }

  List<Expense> get currentPeriodIncome {
    final range = currentPeriodRange;
    return _expenses.where((e) {
      return e.isIncome &&
          !e.date.isBefore(range.startDate) &&
          !e.date.isAfter(range.endDate);
    }).toList();
  }

  double get currentPeriodTotal {
    return currentPeriodExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get currentPeriodFixedTotal {
    return currentPeriodExpenses
        .where((e) => e.expenseKind == ExpenseKind.fixed)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get currentPeriodVariableTotal {
    return currentPeriodTotal - currentPeriodFixedTotal;
  }

  double get currentPeriodOneOffIncome {
    return currentPeriodIncome.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get currentPeriodRecurringIncome {
    if (_baseMonthlyIncome <= 0) return 0.0;
    if (_viewMode == 'weekly') return _baseMonthlyIncome / 4.33;
    if (_viewMode == 'yearly') return _baseMonthlyIncome * 12;
    return _baseMonthlyIncome;
  }

  double get currentPeriodTotalIncome {
    return currentPeriodRecurringIncome + currentPeriodOneOffIncome;
  }

  double get todayTotal {
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.isExpense &&
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day;
    }).fold(0.0, (sum, e) => sum + e.amount);
  }

  MonthlyForecast get forecast {
    final range = currentPeriodRange;
    return ForecastService.calculateForecast(
      currentPeriodExpenses: currentPeriodExpenses,
      monthlyBudget: range.targetBudget,
      now: DateTime.now(),
      periodStart: range.startDate,
      periodEnd: range.endDate,
      totalIncome: currentPeriodTotalIncome,
      recurringIncome: currentPeriodRecurringIncome,
    );
  }

  double get currentPeriodBudget => currentPeriodRange.targetBudget;

  String get currentPeriodLabel => currentPeriodRange.modeName;

  Map<ExpenseCategory, double> get categoryBreakdown {
    final Map<ExpenseCategory, double> totals = {};
    for (var category in ExpenseCategory.values) {
      totals[category] = 0.0;
    }
    for (var expense in currentPeriodExpenses) {
      totals[expense.category] = (totals[expense.category] ?? 0.0) + expense.amount;
    }
    return totals;
  }
}
