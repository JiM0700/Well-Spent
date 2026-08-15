import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/liquid_glass_container.dart';

/// Apple-native analytics screen with Liquid Glass aesthetics (iOS / macOS 26 style).
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final breakdown = provider.categoryBreakdown;
    final totalSpent = provider.currentPeriodTotal;
    final totalIncome = provider.currentPeriodTotalIncome;

    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final dangerColor = CupertinoColors.systemRed.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF07090E) : const Color(0xFFF2F4F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDark ? const Color(0xFF0B0F18) : CupertinoColors.systemBackground).withValues(alpha: 0.85),
        middle: Text('${provider.currentPeriodLabel} Insights', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
          children: [
            // ─── Forecast & Burn Rate Card ──────────────────────────────────────
            LiquidGlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              fillOpacity: 0.08,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Velocity & Spend Forecast',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
                  const SizedBox(height: 10),
                  _infoRow(
                    'Current Velocity',
                    '₹${provider.forecast.dailyVelocity.toStringAsFixed(2)} / day',
                    labelColor,
                    secondaryLabel,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    'Projected Spend',
                    '₹${provider.forecast.projectedMonthEnd.toStringAsFixed(2)}',
                    provider.forecast.projectedMonthEnd > provider.monthlyBudget && provider.monthlyBudget > 0
                        ? dangerColor
                        : primaryColor,
                    secondaryLabel,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    'Safe Daily Burn',
                    '₹${provider.forecast.safeBurnRate.toStringAsFixed(2)} / day',
                    provider.forecast.safeBurnRate > 0 ? primaryColor : dangerColor,
                    secondaryLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Cash Flow Summary ────────────────────────────────────────
            LiquidGlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              fillOpacity: 0.08,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash Flow Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow('Total Income', '₹${totalIncome.toStringAsFixed(2)}', primaryColor, secondaryLabel),
                  const SizedBox(height: 10),
                  _infoRow('Total Spent', '₹${totalSpent.toStringAsFixed(2)}', labelColor, secondaryLabel),
                  const SizedBox(height: 10),
                  _infoRow(
                    'Net Saved',
                    '₹${(totalIncome - totalSpent).toStringAsFixed(2)}',
                    (totalIncome - totalSpent) >= 0 ? primaryColor : dangerColor,
                    secondaryLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Category Breakdown ───────────────────────────────────────
            LiquidGlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              fillOpacity: 0.08,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (totalSpent == 0)
                    Text('No expenses recorded yet', style: TextStyle(color: secondaryLabel, fontSize: 13))
                  else
                    ...breakdown.entries.where((e) => e.value > 0).map((entry) {
                      final pct = (entry.value / totalSpent).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key.displayName,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor)),
                                Text(
                                  '₹${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                                  style: TextStyle(fontSize: 13, color: secondaryLabel, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 6,
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: CupertinoColors.systemFill.resolveFrom(context),
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
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}
