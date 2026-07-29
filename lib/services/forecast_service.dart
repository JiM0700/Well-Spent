import 'dart:math';

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
  final double totalIncome;
  final double recurringIncome;
  final double oneOffIncome;

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
    required this.totalIncome,
    required this.recurringIncome,
    required this.oneOffIncome,
  });
}

class ForecastService {
  /// Calculates velocity and projects end-of-period expense totals.
  static MonthlyForecast calculateForecast({
    required List<Expense> currentPeriodExpenses,
    required double monthlyBudget,
    required DateTime now,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double totalIncome,
    required double recurringIncome,
  }) {
    final totalDaysInMonth = periodEnd.difference(periodStart).inDays + 1;
    final daysElapsed = max(1, now.difference(periodStart).inDays + 1);
    final daysRemaining = max(0, totalDaysInMonth - daysElapsed);

    final double currentTotal = currentPeriodExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    final double dailyVelocity = daysElapsed > 0 ? (currentTotal / daysElapsed) : 0.0;
    final double projectedMonthEnd = currentTotal + (dailyVelocity * daysRemaining);

    final double usagePct = monthlyBudget > 0 ? (projectedMonthEnd / monthlyBudget) * 100 : 0.0;

    String statusMsg;
    if (monthlyBudget <= 0) {
      statusMsg = 'Set a budget target to track spending limits.';
    } else if (projectedMonthEnd > monthlyBudget) {
      final double overrun = projectedMonthEnd - monthlyBudget;
      statusMsg = 'Warning: projected to exceed budget by \$${overrun.toStringAsFixed(2)}.';
    } else if (usagePct >= 85) {
      statusMsg = 'Caution: projected to reach ${usagePct.toStringAsFixed(0)}% of the budget.';
    } else {
      final double savings = monthlyBudget - projectedMonthEnd;
      statusMsg = 'Good pace! On track to save \$${savings.toStringAsFixed(2)} this period.';
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
      totalIncome: totalIncome,
      recurringIncome: recurringIncome,
      oneOffIncome: totalIncome - recurringIncome,
    );
  }
}
