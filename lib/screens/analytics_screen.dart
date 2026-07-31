import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

/// Apple-native analytics screen using CupertinoListSection and
/// CupertinoColors for a clean, grouped-list Apple Settings look.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final breakdown = provider.categoryBreakdown;
    final totalSpent = provider.currentPeriodTotal;
    final totalIncome = provider.currentPeriodTotalIncome;
    final recurringIncome = provider.currentPeriodRecurringIncome;
    final oneOffIncome = provider.currentPeriodOneOffIncome;

    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final dangerColor = CupertinoColors.systemRed.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final bgColor = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final separator = CupertinoColors.separator.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text('${provider.currentPeriodLabel} Analytics'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // ─── Forecast Banner ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Velocity & Forecast',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow(
                    'Days Elapsed',
                    '${provider.forecast.daysElapsed} / ${provider.forecast.totalDaysInMonth} days',
                    labelColor,
                    secondaryLabel,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Current Velocity',
                    '₹${provider.forecast.dailyVelocity.toStringAsFixed(2)} / day',
                    labelColor,
                    secondaryLabel,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Projected Period End',
                    '₹${provider.forecast.projectedMonthEnd.toStringAsFixed(2)}',
                    provider.forecast.projectedMonthEnd > provider.currentPeriodBudget
                        ? dangerColor
                        : primaryColor,
                    secondaryLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Income Overview ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow('Recurring Income', '₹${recurringIncome.toStringAsFixed(2)}',
                      labelColor, secondaryLabel),
                  const SizedBox(height: 8),
                  _infoRow('One-off Income', '₹${oneOffIncome.toStringAsFixed(2)}',
                      labelColor, secondaryLabel),
                  const SizedBox(height: 10),
                  Container(height: 0.5, color: separator.withValues(alpha:0.5)),
                  const SizedBox(height: 10),
                  _infoRow('Total Net Income', '₹${totalIncome.toStringAsFixed(2)}',
                      primaryColor, secondaryLabel),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Spending by Category ─────────────────────────────────
            Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 12),

            if (totalSpent == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No spending data for this period yet.',
                    style: TextStyle(fontSize: 15, color: secondaryLabel),
                  ),
                ),
              )
            else
              ...ExpenseCategory.values.map((category) {
                final amount = breakdown[category] ?? 0.0;
                if (amount == 0) return const SizedBox.shrink();

                final pct = (amount / totalSpent);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: labelColor,
                            ),
                          ),
                          Text(
                            '₹${amount.toStringAsFixed(2)} (${(pct * 100).toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: separator.withValues(alpha:0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: labelColor)),
        Text(value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
