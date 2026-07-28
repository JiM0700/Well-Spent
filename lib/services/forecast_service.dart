import '../models/expense.dart';

class MonthlyForecast {
  final double currentTotal;
  final double projectedMonthEnd;
  final double dailyVelocity;
  final double monthlyBudget;
  final int daysElapsed;
  final int daysRemaining;
  final int totalDaysInMonth;
  final double projectedBudgetUsagePercentage;
  final String statusMessage;

  MonthlyForecast({
    required this.currentTotal,
    required this.projectedMonthEnd,
    required this.dailyVelocity,
    required this.monthlyBudget,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.totalDaysInMonth,
    required this.projectedBudgetUsagePercentage,
    required this.statusMessage,
  });
}

class ForecastService {
  /// Calculates spending velocity and projects end-of-month expense total.
  static MonthlyForecast calculateForecast({
    required List<Expense> currentMonthExpenses,
    required double monthlyBudget,
    required DateTime now,
  }) {
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day > 0 ? now.day : 1;
    final daysRemaining = totalDaysInMonth - daysElapsed;

    final double currentTotal = currentMonthExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    final double dailyVelocity = daysElapsed > 0 ? (currentTotal / daysElapsed) : 0.0;

    // Projected total = Spent so far + (daily velocity * remaining days)
    final double projectedMonthEnd = currentTotal + (dailyVelocity * daysRemaining);

    final double usagePct = monthlyBudget > 0
        ? (projectedMonthEnd / monthlyBudget) * 100
        : 0.0;

    String statusMsg;
    if (monthlyBudget <= 0) {
      statusMsg = 'Set a monthly budget to track spending limits.';
    } else if (projectedMonthEnd > monthlyBudget) {
      final double overrun = projectedMonthEnd - monthlyBudget;
      statusMsg = 'Warning: On track to exceed budget by \$${overrun.toStringAsFixed(2)}';
    } else if (usagePct >= 85) {
      statusMsg = 'Caution: Projected to reach ${usagePct.toStringAsFixed(0)}% of monthly budget.';
    } else {
      final double savings = monthlyBudget - projectedMonthEnd;
      statusMsg = 'Great pace! On track to save \$${savings.toStringAsFixed(2)} this month.';
    }

    return MonthlyForecast(
      currentTotal: currentTotal,
      projectedMonthEnd: projectedMonthEnd,
      dailyVelocity: dailyVelocity,
      monthlyBudget: monthlyBudget,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      totalDaysInMonth: totalDaysInMonth,
      projectedBudgetUsagePercentage: usagePct,
      statusMessage: statusMsg,
    );
  }
}
