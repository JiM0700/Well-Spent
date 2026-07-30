import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDataMenu(BuildContext context, ExpenseProvider provider) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(600, 80, 12, 0),
      items: const [
        PopupMenuItem(value: 'export', child: Text('Export CSV')),
        PopupMenuItem(value: 'import', child: Text('Import CSV')),
      ],
    ).then((value) {
      if (value == 'export') _exportCsv(context, provider);
      if (value == 'import') _importCsv(context, provider);
    });
  }

  Future<void> _exportCsv(BuildContext context, ExpenseProvider provider) async {
    await Clipboard.setData(ClipboardData(text: provider.exportCsv()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
  }

  Future<void> _importCsv(BuildContext context, ExpenseProvider provider) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import CSV'),
        content: SizedBox(width: 520, child: TextField(controller: controller, maxLines: 10, decoration: const InputDecoration(hintText: 'Paste a Well Spent CSV export here', border: OutlineInputBorder()))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () async { final count = await provider.importCsv(controller.text); if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count entries imported'))); } }, child: const Text('Replace data')),
        ],
      ),
    );
    controller.dispose();
  }

  void _showAddExpenseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QuickAddModal(),
    );
  }

  void _showSetBudgetDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(text: provider.monthlyBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Budget (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                provider.updateMonthlyBudget(val);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSetCycleStartDayDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(text: provider.cycleStartDay.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Cycle Start Day'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cycle Start Day',
            helperText: 'Enter a day between 1 and 28',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 1 && val <= 28) {
                provider.updateCycleStartDay(val);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSetBaseIncomeDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(text: provider.baseMonthlyIncome.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Base Monthly Income'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Base Monthly Income (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                provider.updateBaseMonthlyIncome(val);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSetPayDayDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(text: provider.payDay.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Payday'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Payday',
            helperText: 'Enter a day between 1 and 28',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 1 && val <= 28) {
                provider.updatePayDay(val);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.bills:
        return Icons.receipt_long;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.healthcare:
        return Icons.medical_services;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.invest:
        return Icons.savings;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Widget _settingPill({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: theme.colorScheme.surfaceVariant,
      elevation: 0,
      labelStyle: theme.textTheme.bodyMedium,
    );
  }

  Widget _buildSurface(
    BuildContext context,
    Widget child, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry margin = EdgeInsets.zero,
    double? animationDelay,
  }) {
    final theme = Theme.of(context);
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final isDark = theme.brightness == Brightness.dark;

    final surface = isMac
        ? Container(
            margin: margin,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              theme.colorScheme.surface.withOpacity(0.84),
                              theme.colorScheme.surface.withOpacity(0.6),
                            ]
                          : [
                              theme.colorScheme.surface.withOpacity(0.86),
                              theme.colorScheme.surface.withOpacity(0.62),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.7), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.22 : 0.12),
                        blurRadius: 30,
                        spreadRadius: 1,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(isDark ? 0.07 : 0.16),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          )
        : Card(
            margin: margin,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: padding,
              child: child,
            ),
          );

    if (animationDelay == null) {
      return surface;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final curvedValue = CurvedAnimation(
          parent: _controller,
          curve: Interval(animationDelay, 1.0, curve: Curves.easeOutCubic),
        ).value;

        return Transform.translate(
          offset: Offset(0, 18 * (1 - curvedValue)),
          child: Opacity(
            opacity: curvedValue.clamp(0.0, 1.0),
            child: surface,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ExpenseProvider>(context);
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    final PreferredSizeWidget? appBar = defaultTargetPlatform == TargetPlatform.iOS
        ? PreferredSize(
            preferredSize: const Size.fromHeight(kMinInteractiveDimensionCupertino),
            child: CupertinoNavigationBar(
              middle: const Text('Well Spent'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => Navigator.of(context).pushNamed('/analytics'),
                child: const Icon(CupertinoIcons.chart_bar),
              ),
            ),
          )
        : AppBar(
            title: const Row(children: [
              Icon(Icons.account_balance_wallet_outlined),
              SizedBox(width: 8),
              Text('Well Spent', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Analytics & Forecasting',
                onPressed: () => Navigator.of(context).pushNamed('/analytics'),
              ),
              if (defaultTargetPlatform != TargetPlatform.iOS)
                IconButton(
                  icon: const Icon(Icons.import_export),
                  tooltip: 'Import or export CSV',
                  onPressed: () => _showDataMenu(context, provider),
                ),
            ],
          );

    return Scaffold(
      backgroundColor: isMac ? Colors.transparent : null,
      appBar: appBar,
      body: Container(
        decoration: isMac
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface.withOpacity(0.98),
                    theme.colorScheme.primary.withOpacity(0.08),
                    theme.colorScheme.secondary.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => provider.loadData(),
                child: CustomScrollView(
                  slivers: [
                    if (isMac)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: _buildSurface(
                            context,
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Well Spent', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text('Liquid glass overview for your money', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            animationDelay: 0.02,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, isMac ? 8 : 16, 20, 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: {
                                'weekly': 'Weekly',
                                'monthly': 'Monthly',
                                'yearly': 'Yearly'
                              }.entries.map((entry) {
                                final isSelected = provider.viewMode == entry.key;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(entry.value),
                                    selected: isSelected,
                                    onSelected: (_) => provider.updateViewMode(entry.key),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            _buildSurface(
                              context,
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
                              padding: EdgeInsets.zero,
                              margin: EdgeInsets.zero,
                              animationDelay: 0.08,
                            ),
                            const SizedBox(height: 16),
                            _buildSurface(
                              context,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cycle & Income Settings',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _settingPill(
                                        context: context,
                                        label: 'Cycle day: ${provider.cycleStartDay}',
                                        icon: Icons.calendar_today,
                                        onTap: () => _showSetCycleStartDayDialog(context, provider),
                                      ),
                                      _settingPill(
                                        context: context,
                                        label: 'Payday: ${provider.payDay}',
                                        icon: Icons.paypal,
                                        onTap: () => _showSetPayDayDialog(context, provider),
                                      ),
                                      _settingPill(
                                        context: context,
                                        label: 'Income: ₹${provider.baseMonthlyIncome.toStringAsFixed(0)}',
                                        icon: Icons.attach_money,
                                        onTap: () => _showSetBaseIncomeDialog(context, provider),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Enable spending summary'),
                                    value: provider.summaryEnabled,
                                    onChanged: provider.updateSummaryEnabled,
                                  ),
                                  if (provider.summaryEnabled) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: ['daily', 'weekly', 'monthly'].map((option) {
                                        final label = option == 'daily'
                                            ? 'Daily'
                                            : option == 'weekly'
                                                ? 'Weekly'
                                                : 'Monthly';
                                        return ChoiceChip(
                                          label: Text(label),
                                          selected: provider.summaryPeriod == option,
                                          onSelected: (_) => provider.updateSummaryPeriod(option),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: ['daywise', 'monthwise'].map((option) {
                                      final label = option == 'daywise' ? 'Daywise' : 'Monthwise';
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ChoiceChip(
                                          label: Text(label),
                                          selected: provider.chartMode == option,
                                          onSelected: (_) => provider.updateChartMode(option),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16.0),
                            ),
                            const SizedBox(height: 16),
                            _buildSurface(
                              context,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.chartMode == 'monthwise' ? 'Monthly Chart' : 'Daywise Chart',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 240,
                                    child: _ExpenseChart(provider: provider),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16.0),
                              animationDelay: 0.2,
                            ),
                            const SizedBox(height: 16),
                            _buildSurface(
                              context,
                              ForecastCard(forecast: provider.forecast),
                              padding: EdgeInsets.zero,
                              margin: EdgeInsets.zero,
                              animationDelay: 0.26,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Transactions',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (provider.selectedCategoryFilter != null)
                                  TextButton(
                                    onPressed: () => provider.filterByCategory(null),
                                    child: const Text('Clear Filter'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterChip(
                                    label: const Text('All'),
                                    selected: provider.selectedCategoryFilter == null,
                                    onSelected: (_) => provider.filterByCategory(null),
                                  ),
                                  const SizedBox(width: 8),
                                  ...ExpenseCategory.values.map((cat) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: FilterChip(
                                        label: Text(cat.displayName),
                                        selected: provider.selectedCategoryFilter == cat,
                                        onSelected: (_) => provider.filterByCategory(cat),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (provider.expenses.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.outline),
                              const SizedBox(height: 12),
                              Text(
                                'No expenses recorded yet.',
                                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap the + button to add your first entry!',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  if (item.id != null) {
                                    provider.deleteExpense(item.id!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Deleted "${item.title}"')),
                                    );
                                  }
                                },
                                child: _buildSurface(
                                  context,
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        _getCategoryIcon(item.category),
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '${item.category.displayName} • ${DateFormat('MMM d, yyyy').format(item.date)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      item.isIncome ? '+₹${item.amount.toStringAsFixed(2)}' : '-₹${item.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: item.isIncome ? theme.colorScheme.primary : theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.zero,
                                  animationDelay: index * 0.04,
                                ),
                              );
                            },
                            childCount: provider.expenses.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
      ),
      floatingActionButton: defaultTargetPlatform == TargetPlatform.iOS
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddExpenseModal(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
    );
  }
}

class _ExpenseChart extends StatelessWidget {
  final ExpenseProvider provider;

  const _ExpenseChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataPoints = provider.chartData;
    if (dataPoints.isEmpty) {
      return Center(
        child: Text(
          'No chart data available yet.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

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
              color: theme.colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxValue > 0 ? maxValue / 4 : 1,
                getTitlesWidget: (value, meta) => Text(
                  value == 0 ? '0' : value.toStringAsFixed(0),
                  style: theme.textTheme.bodySmall,
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
                    child: Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
          ),
          minY: 0,
          maxY: maxValue * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
