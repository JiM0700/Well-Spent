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

    Widget content = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (showNavigationBar)
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Insights',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
            ),
            backgroundColor: (isDark ? const Color(0xFF0A0E18) : CupertinoColors.systemBackground).withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: isDark ? CupertinoColors.white.withValues(alpha: 0.08) : CupertinoColors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            stretch: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: isDark ? CupertinoColors.white.withValues(alpha: 0.08) : CupertinoColors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${provider.currentPeriodLabel} View',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: secondaryLabel,
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
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
                    _infoRow(
                      'Base Monthly Income',
                      '₹${provider.baseMonthlyIncome.toStringAsFixed(2)}',
                      primaryColor,
                      secondaryLabel,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      'Period Income Added',
                      '₹${totalIncome.toStringAsFixed(2)}',
                      primaryColor,
                      secondaryLabel,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      'Total Spent',
                      '₹${totalSpent.toStringAsFixed(2)}',
                      dangerColor,
                      secondaryLabel,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        height: 0.8,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.08)
                            : CupertinoColors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    _infoRow(
                      'Net Saved / Remaining',
                      '₹${(provider.baseMonthlyIncome + totalIncome - totalSpent).toStringAsFixed(2)}',
                      (provider.baseMonthlyIncome + totalIncome - totalSpent) >= 0 ? primaryColor : dangerColor,
                      labelColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Category Breakdown Card ────────────────────────────────────────
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
                    const SizedBox(height: 14),
                    if (breakdown.isEmpty || totalSpent == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No expense data available for this cycle',
                            style: TextStyle(fontSize: 13, color: secondaryLabel),
                          ),
                        ),
                      )
                    else
                      ...ExpenseCategory.values.map((category) {
                        final amt = breakdown[category] ?? 0;
                        if (amt == 0) return const SizedBox.shrink();
                        final pct = totalSpent > 0 ? (amt / totalSpent) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    category.displayName,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
                                  ),
                                  Text(
                                    '₹${amt.toStringAsFixed(2)}  (${(pct * 100).toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontSize: 12,
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
            ]),
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
      child: content,
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
