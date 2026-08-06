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
import '../widgets/quick_add_modal.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  void _showAddExpenseModal(BuildContext context) {
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
        return CupertinoIcons.cart;
      case ExpenseCategory.transport:
        return CupertinoIcons.car_detailed;
      case ExpenseCategory.bills:
        return CupertinoIcons.doc_text;
      case ExpenseCategory.shopping:
        return CupertinoIcons.bag;
      case ExpenseCategory.healthcare:
        return CupertinoIcons.heart;
      case ExpenseCategory.entertainment:
        return CupertinoIcons.film;
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

    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final bgColor = CupertinoColors.systemGroupedBackground.resolveFrom(context);

    if (provider.isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Well Spent')),
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    // View mode segments
    final viewModeSegments = <String, Widget>{
      'weekly': const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Weekly')),
      'monthly': const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Monthly')),
      'yearly': const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Yearly')),
    };

    // Chart mode segments
    final chartModeSegments = <String, Widget>{
      'daywise': const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Daywise')),
      'monthwise': const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Monthwise')),
    };

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Well Spent'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isIOS)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                child: const Icon(CupertinoIcons.arrow_up_arrow_down, size: 22),
                onPressed: () => _showDataMenu(context, provider),
              ),
            if (!isIOS) const SizedBox(width: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              child: const Icon(CupertinoIcons.add, size: 26),
              onPressed: () => _showAddExpenseModal(context),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Period selector
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: provider.viewMode,
                      children: viewModeSegments,
                      onValueChanged: (val) {
                        if (val != null) provider.updateViewMode(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary card
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

                  // Chart section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.chartMode == 'monthwise' ? 'Monthly Chart' : 'Daywise Chart',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoSlidingSegmentedControl<String>(
                            groupValue: provider.chartMode,
                            children: chartModeSegments,
                            onValueChanged: (val) {
                              if (val != null) provider.updateChartMode(val);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: _ExpenseChart(provider: provider),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Forecast card
                  ForecastCard(forecast: provider.forecast),
                  const SizedBox(height: 24),

                  // Transactions header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                      if (provider.selectedCategoryFilter != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          child: Text('Clear Filter',
                              style: TextStyle(fontSize: 15, color: primaryColor)),
                          onPressed: () => provider.filterByCategory(null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: provider.selectedCategoryFilter == null,
                          onTap: () => provider.filterByCategory(null),
                        ),
                        ...ExpenseCategory.values.map((cat) => _FilterChip(
                              label: cat.displayName,
                              selected: provider.selectedCategoryFilter == cat,
                              onTap: () => provider.filterByCategory(cat),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),

            // Transaction list
            if (provider.expenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.doc_text, size: 56, color: secondaryLabel),
                      const SizedBox(height: 12),
                      Text(
                        'No expenses recorded yet.',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: secondaryLabel),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add your first entry!',
                        style: TextStyle(fontSize: 15, color: secondaryLabel),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          margin: const EdgeInsets.only(bottom: 1),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.resolveFrom(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
                        ),
                        onDismissed: (_) {
                          if (item.id != null) {
                            provider.deleteExpense(item.id!);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(
                              _transactionRadius(index, provider.expenses.length),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Category icon
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(item.category),
                                  size: 18,
                                  color: primaryColor,
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
                                      style: TextStyle(fontSize: 13, color: secondaryLabel),
                                    ),
                                  ],
                                ),
                              ),
                              // Amount
                              Text(
                                '${item.isIncome ? '+' : '-'}₹${item.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: item.isIncome ? primaryColor : labelColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: provider.expenses.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  /// Round the top corners of the first item and bottom corners of the last
  /// to form grouped-style list sections.
  double _transactionRadius(int index, int total) {
    if (total == 1) return 12;
    if (index == 0 || index == total - 1) return 12;
    return 0;
  }
}

// ─── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final fillColor = CupertinoColors.tertiarySystemFill.resolveFrom(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? primaryColor : fillColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? CupertinoColors.white : labelColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chart ──────────────────────────────────────────────────────────────────

class _ExpenseChart extends StatelessWidget {
  final ExpenseProvider provider;

  const _ExpenseChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final dataPoints = provider.chartData;
    if (dataPoints.isEmpty) {
      return Center(
        child: Text(
          'No chart data available yet.',
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final gridColor = CupertinoColors.separator.resolveFrom(context);
    final labelColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    final maxValue = dataPoints.map((p) => p.amount).fold<double>(0.0, (prev, value) => max(prev, value));
    final spots = List.generate(dataPoints.length, (index) {
      return FlSpot(index.toDouble(), dataPoints[index].amount);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: gridColor.withValues(alpha: 0.3),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxValue > 0 ? maxValue / 4 : 1,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => Text(
                  value == 0 ? '0' : value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 10, color: labelColor),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dataPoints.length) return const SizedBox.shrink();
                  final label = dataPoints[index].label;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxValue * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primaryColor,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
