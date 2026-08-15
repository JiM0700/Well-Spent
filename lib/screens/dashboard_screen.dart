import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/forecast_card.dart';
import '../widgets/liquid_glass_chip.dart';
import '../widgets/liquid_glass_container.dart';
import '../widgets/quick_add_modal.dart';
import '../widgets/recurring_bills_card.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _showAddExpenseModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => const QuickAddModal(),
    );
  }

  void _showSetBudgetDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(text: provider.monthlyBudget.toStringAsFixed(0));
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Set Monthly Budget'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Text('₹ ')),
          ),
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) provider.updateMonthlyBudget(val);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDataMenu(BuildContext context, ExpenseProvider provider) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Export CSV'),
            onPressed: () {
              Navigator.pop(context);
              _exportCsv(context, provider);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Import CSV'),
            onPressed: () {
              Navigator.pop(context);
              _importCsv(context, provider);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, ExpenseProvider provider) async {
    await Clipboard.setData(ClipboardData(text: provider.exportCsv()));
    if (!context.mounted) return;
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('CSV copied'),
        content: const Text('Your data was copied to the clipboard.'),
        actions: [
          CupertinoDialogAction(child: const Text('Done'), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Future<void> _importCsv(BuildContext context, ExpenseProvider provider) async {
    final controller = TextEditingController();
    await showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Import CSV'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 8,
            placeholder: 'Paste a Well Spent CSV export here',
          ),
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Replace data'),
            onPressed: () async {
              final count = await provider.importCsv(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                showCupertinoDialog<void>(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: const Text('Import complete'),
                    content: Text('$count entries imported.'),
                    actions: [
                      CupertinoDialogAction(
                          child: const Text('Done'), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
    controller.dispose();
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return CupertinoIcons.cart_fill;
      case ExpenseCategory.transport:
        return CupertinoIcons.car_detailed;
      case ExpenseCategory.bills:
        return CupertinoIcons.doc_text_fill;
      case ExpenseCategory.shopping:
        return CupertinoIcons.bag_fill;
      case ExpenseCategory.healthcare:
        return CupertinoIcons.heart_fill;
      case ExpenseCategory.entertainment:
        return CupertinoIcons.film_fill;
      case ExpenseCategory.invest:
        return CupertinoIcons.chart_bar_alt_fill;
      case ExpenseCategory.other:
        return CupertinoIcons.ellipsis;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    if (provider.isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Well Spent')),
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    final viewModeSegments = <String, Widget>{
      'weekly': const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('Weekly')),
      'monthly': const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('Monthly')),
      'yearly': const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('Yearly')),
    };

    final chartModeSegments = <String, Widget>{
      'daywise': const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text('Daywise')),
      'monthwise': const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text('Monthwise')),
    };

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF07090E) : const Color(0xFFF2F4F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDark ? const Color(0xFF0B0F18) : CupertinoColors.systemBackground).withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: isDark ? CupertinoColors.white.withValues(alpha: 0.12) : CupertinoColors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        middle: const Text(
          'Well Spent',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isIOS)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                child: Icon(CupertinoIcons.arrow_up_arrow_down, size: 20, color: labelColor),
                onPressed: () => _showDataMenu(context, provider),
              ),
            if (!isIOS) const SizedBox(width: 14),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.plus, size: 20, color: primaryColor),
              ),
              onPressed: () => _showAddExpenseModal(context),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Liquid Glass Period Selector
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: provider.viewMode,
                      backgroundColor: isDark ? CupertinoColors.white.withValues(alpha: 0.08) : CupertinoColors.black.withValues(alpha: 0.05),
                      thumbColor: isDark ? const Color(0xFF1B2232) : CupertinoColors.white,
                      children: viewModeSegments,
                      onValueChanged: (val) {
                        if (val != null) {
                          HapticFeedback.selectionClick();
                          provider.updateViewMode(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Liquid Glass Summary Card
                  SummaryCard(
                    periodLabel: provider.currentPeriodLabel,
                    periodTotal: provider.currentPeriodTotal,
                    todayTotal: provider.todayTotal,
                    periodBudget: provider.currentPeriodBudget,
                    onEditBudget: () => _showSetBudgetDialog(context, provider),
                    summaryEnabled: provider.summaryEnabled,
                    summaryWindowLabel: provider.summaryPeriodLabel,
                    summaryRangeLabel: provider.summaryRangeLabel,
                    summaryDifferenceLabel: provider.summaryDifferenceLabel,
                    summaryTopCategoryLabel: provider.summaryTopCategoryLabel,
                  ),
                  const SizedBox(height: 16),

                  // Liquid Glass Chart Section
                  LiquidGlassContainer(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    fillOpacity: 0.08,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.chartMode == 'monthwise' ? 'Spending Trend (Monthly)' : 'Spending Trend (Daily)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: labelColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoSlidingSegmentedControl<String>(
                            groupValue: provider.chartMode,
                            thumbColor: isDark ? const Color(0xFF1E2638) : CupertinoColors.white,
                            children: chartModeSegments,
                            onValueChanged: (val) {
                              if (val != null) {
                                HapticFeedback.selectionClick();
                                provider.updateChartMode(val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: _ExpenseChart(provider: provider),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Liquid Glass Forecast Card
                  ForecastCard(forecast: provider.forecast),
                  const SizedBox(height: 16),

                  // Recurring Bills & Subscriptions Card
                  const RecurringBillsCard(),
                  const SizedBox(height: 24),

                  // Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: labelColor,
                        ),
                      ),
                      if (provider.selectedCategoryFilter != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          child: Text('Reset Filter',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor)),
                          onPressed: () => provider.filterByCategory(null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        LiquidGlassChip(
                          label: 'All Activity',
                          isSelected: provider.selectedCategoryFilter == null,
                          onPressed: () => provider.filterByCategory(null),
                        ),
                        const SizedBox(width: 8),
                        ...ExpenseCategory.values.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: LiquidGlassChip(
                                label: cat.displayName,
                                isSelected: provider.selectedCategoryFilter == cat,
                                onPressed: () => provider.filterByCategory(cat),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ]),
              ),
            ),

            // Transactions List
            if (provider.expenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.sparkles, size: 48, color: secondaryLabel),
                        const SizedBox(height: 14),
                        Text(
                          'No entries in this period',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: labelColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to log your first transaction.',
                          style: TextStyle(fontSize: 14, color: secondaryLabel),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = provider.expenses[index];
                      return Dismissible(
                        key: Key(item.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.resolveFrom(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(CupertinoIcons.delete_solid, color: CupertinoColors.white),
                        ),
                        onDismissed: (_) {
                          if (item.id != null) {
                            HapticFeedback.lightImpact();
                            provider.deleteExpense(item.id!);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: LiquidGlassContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            fillOpacity: 0.06,
                            child: Row(
                              children: [
                                // Category icon in frosted circle
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (item.isIncome ? primaryColor : CupertinoColors.activeBlue)
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(item.category),
                                    size: 18,
                                    color: item.isIncome ? primaryColor : CupertinoColors.activeBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title & subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: labelColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.category.displayName} · ${DateFormat('MMM d').format(item.date)}',
                                        style: TextStyle(fontSize: 12, color: secondaryLabel),
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
                                Text(
                                  '${item.isIncome ? '+' : '-'}₹${item.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: item.isIncome ? primaryColor : labelColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: provider.expenses.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _ExpenseChart extends StatelessWidget {
  final ExpenseProvider provider;
  const _ExpenseChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final chartPoints = provider.chartData;
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);

    if (chartPoints.isEmpty || chartPoints.every((s) => s.amount == 0)) {
      return Center(
        child: Text(
          'No chart data available yet',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 13,
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < chartPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), chartPoints[i].amount));
    }

    final maxY = spots.map((s) => s.y).reduce(max);
    final effectiveMaxY = maxY > 0 ? maxY * 1.2 : 100.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3),
            strokeWidth: 0.8,
          ),
        ),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: spots.first.x,
        maxX: spots.last.x,
        minY: 0,
        maxY: effectiveMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: primaryColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.3),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
