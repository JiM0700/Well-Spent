import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/liquid_glass_container.dart';

/// Apple-native analytics screen with Liquid Glass aesthetics (iOS / macOS 26 style).
class AnalyticsScreen extends StatelessWidget {
  final bool showNavigationBar;

  const AnalyticsScreen({
    super.key,
    this.showNavigationBar = true,
  });

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

    Widget content = ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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

        // ─── Cash Flow Overview Card ─────────────────────────────────────────
        LiquidGlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          fillOpacity: 0.08,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Period Cash Flow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 14),
              _infoRow('Base Income', '₹${totalIncome.toStringAsFixed(2)}', primaryColor, secondaryLabel),
              const SizedBox(height: 10),
              _infoRow('Total Outflow', '₹${totalSpent.toStringAsFixed(2)}', dangerColor, secondaryLabel),
              const SizedBox(height: 10),
              _infoRow(
                'Net Cash Flow',
                '${totalIncome - totalSpent >= 0 ? '+' : ''}₹${(totalIncome - totalSpent).toStringAsFixed(2)}',
                totalIncome - totalSpent >= 0 ? primaryColor : dangerColor,
                secondaryLabel,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── Category Breakdown Card ─────────────────────────────────────────
        LiquidGlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          fillOpacity: 0.08,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 16),
              if (totalSpent == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No spending data yet', style: TextStyle(color: secondaryLabel)),
                  ),
                )
              else
                ...ExpenseCategory.values.map((cat) {
                  final amount = breakdown[cat] ?? 0.0;
                  if (amount <= 0) return const SizedBox.shrink();
                  final pct = amount / totalSpent;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: labelColor,
                              ),
                            ),
                            Text(
                              '₹${amount.toStringAsFixed(0)} · ${(pct * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: secondaryLabel,
                              ),
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
                              backgroundColor: isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.08)
                                  : CupertinoColors.black.withValues(alpha: 0.06),
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
    );

    if (!showNavigationBar) {
      return Container(
        color: isDark ? const Color(0xFF06080E) : const Color(0xFFF1F3F6),
        child: content,
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF06080E) : const Color(0xFFF1F3F6),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDark ? const Color(0xFF0A0E18) : CupertinoColors.systemBackground).withValues(alpha: 0.85),
        middle: Text('${provider.currentPeriodLabel} Insights', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      child: SafeArea(child: content),
    );
  }

  Widget _infoRow(String label, String value, Color valColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: labelColor, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valColor),
        ),
      ],
    );
  }
}
