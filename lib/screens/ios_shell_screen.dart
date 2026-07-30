import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'analytics_screen.dart';
import 'category_library_screen.dart';
import 'dashboard_screen.dart';
import '../widgets/quick_add_modal.dart';
import '../providers/expense_provider.dart';
import 'package:provider/provider.dart';

/// The iPhone information architecture. The tab bar stays focused on the
/// user's four recurring jobs; categories live in their own library instead
/// of competing with the primary navigation.
class IosShellScreen extends StatefulWidget {
  const IosShellScreen({super.key});

  @override
  State<IosShellScreen> createState() => _IosShellScreenState();
}

class _IosShellScreenState extends State<IosShellScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    const MethodChannel('well_spent/liquid-glass-bar').setMethodCallHandler((call) async {
      final state = _shellState;
      if (state == null || !state.mounted) return;
      if (call.method == 'selectTab') state.setState(() => state._selectedIndex = call.arguments as int);
      if (call.method == 'addExpense') state._openAddExpense();
    });
    _shellState = this;
  }

  @override
  void dispose() {
    if (identical(_shellState, this)) _shellState = null;
    super.dispose();
  }

  static _IosShellScreenState? _shellState;

  void _openAddExpense() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(child: _pageForIndex(_selectedIndex)),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _NavigationPill(
                      selectedIndex: _selectedIndex,
                      onSelected: (index) => setState(() => _selectedIndex = index),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _AddExpensePill(onPressed: _openAddExpense),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 1: return const CategoryLibraryScreen();
      case 2: return const AnalyticsScreen();
      case 3: return const _IosSettingsScreen();
      default: return const DashboardScreen();
    }
  }
}

class _NavigationPill extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _NavigationPill({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const items = [
      (CupertinoIcons.chart_bar, 'Overview'),
      (CupertinoIcons.square_grid_2x2, 'Categories'),
      (CupertinoIcons.waveform_path_ecg, 'Insights'),
      (CupertinoIcons.gear, 'Settings'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.white.withOpacity(0.16), Colors.white.withOpacity(0.08)]
                  : [Colors.white.withOpacity(0.78), Colors.white.withOpacity(0.48)],
            ),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.72), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.24 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final selected = selectedIndex == index;
              final item = items[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary.withOpacity(isDark ? 0.24 : 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.$1,
                          size: 19,
                          color: selected ? theme.colorScheme.primary : (isDark ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AddExpensePill extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddExpensePill({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPressed,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [theme.colorScheme.primary.withOpacity(0.95), theme.colorScheme.secondary.withOpacity(0.8)]
                    : [theme.colorScheme.primary.withOpacity(0.95), theme.colorScheme.secondary.withOpacity(0.78)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.32 : 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.plus, color: Colors.white, size: 27),
          ),
        ),
      ),
    );
  }
}

class _IosSettingsScreen extends StatelessWidget {
  const _IosSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('BUDGETING', style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: const Text('Export CSV'),
                  leading: const Icon(CupertinoIcons.arrow_up_doc),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _exportCsv(context, provider),
                ),
                CupertinoListTile(
                  title: const Text('Import CSV'),
                  leading: const Icon(CupertinoIcons.arrow_down_doc),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _importCsv(context, provider),
                ),
                CupertinoListTile(
                  title: const Text('Monthly budget'),
                  additionalInfo: Text('₹${provider.monthlyBudget.toStringAsFixed(0)}'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _editBudget(context, provider),
                ),
                CupertinoListTile(
                  title: const Text('Cycle starts on'),
                  additionalInfo: Text('${provider.cycleStartDay}'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _editCycleDay(context, provider),
                ),
                CupertinoListTile(
                  title: const Text('Monthly income'),
                  additionalInfo: Text('₹${provider.baseMonthlyIncome.toStringAsFixed(0)}'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _editIncome(context, provider),
                ),
                CupertinoListTile(
                  title: const Text('Payday'),
                  additionalInfo: Text('Day ${provider.payDay}'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _editPayday(context, provider),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Text('SUMMARIES', style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: const Text('Spending summary'),
                  trailing: CupertinoSwitch(
                    value: provider.summaryEnabled,
                    onChanged: provider.updateSummaryEnabled,
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Summary period'),
                  additionalInfo: Text(_periodLabel(provider.summaryPeriod)),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _choosePeriod(context, provider),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Text('ABOUT', style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(title: Text('Well Spent'), additionalInfo: Text('Offline-first')),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static String _periodLabel(String period) => switch (period) {
    'daily' => 'Today',
    'weekly' => 'Last 7 days',
    _ => 'This month',
  };

  static Future<void> _editBudget(BuildContext context, ExpenseProvider provider) async {
    final controller = TextEditingController(text: provider.monthlyBudget.toStringAsFixed(0));
    await showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Monthly budget'),
        content: Padding(padding: const EdgeInsets.only(top: 12), child: CupertinoTextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), prefix: const Text('₹ '))),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(child: const Text('Save'), onPressed: () { final value = double.tryParse(controller.text); if (value != null) provider.updateMonthlyBudget(value); Navigator.pop(context); }),
        ],
      ),
    );
    controller.dispose();
  }

  static Future<void> _editCycleDay(BuildContext context, ExpenseProvider provider) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Cycle starts on'),
        actions: [5, 10, 15, 20, 25, 1].map((day) => CupertinoActionSheetAction(onPressed: () { provider.updateCycleStartDay(day); Navigator.pop(context); }, child: Text('Day $day'))).toList(),
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ),
    );
  }

  static Future<void> _editIncome(BuildContext context, ExpenseProvider provider) async {
    final controller = TextEditingController(text: provider.baseMonthlyIncome.toStringAsFixed(0));
    await showCupertinoDialog<void>(context: context, builder: (_) => CupertinoAlertDialog(
      title: const Text('Monthly income'),
      content: Padding(padding: const EdgeInsets.only(top: 12), child: CupertinoTextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), prefix: const Text('₹ '))),
      actions: [CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)), CupertinoDialogAction(child: const Text('Save'), onPressed: () { final value = double.tryParse(controller.text); if (value != null) provider.updateBaseMonthlyIncome(value); Navigator.pop(context); })],
    ));
    controller.dispose();
  }

  static Future<void> _editPayday(BuildContext context, ExpenseProvider provider) async {
    await showCupertinoModalPopup<void>(context: context, builder: (_) => CupertinoActionSheet(
      title: const Text('Payday'),
      actions: List.generate(31, (index) => index + 1).map((day) => CupertinoActionSheetAction(onPressed: () { provider.updatePayDay(day); Navigator.pop(context); }, child: Text('Day $day'))).toList(),
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
    ));
  }

  static Future<void> _choosePeriod(BuildContext context, ExpenseProvider provider) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Summary period'),
        actions: {'daily': 'Today', 'weekly': 'Last 7 days', 'monthly': 'This month'}.entries.map((entry) => CupertinoActionSheetAction(onPressed: () { provider.updateSummaryPeriod(entry.key); Navigator.pop(context); }, child: Text(entry.value))).toList(),
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ),
    );
  }

  static Future<void> _exportCsv(BuildContext context, ExpenseProvider provider) async {
    await Clipboard.setData(ClipboardData(text: provider.exportCsv()));
    if (context.mounted) {
      showCupertinoDialog<void>(context: context, builder: (_) => CupertinoAlertDialog(
        title: const Text('CSV copied'),
        content: const Text('Your data was copied as CSV. Paste it into a file or spreadsheet to save a backup.'),
        actions: [CupertinoDialogAction(child: const Text('Done'), onPressed: () => Navigator.pop(context))],
      ));
    }
  }

  static Future<void> _importCsv(BuildContext context, ExpenseProvider provider) async {
    final controller = TextEditingController();
    await showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Import CSV'),
        content: Padding(padding: const EdgeInsets.only(top: 12), child: CupertinoTextField(controller: controller, maxLines: 8, placeholder: 'Paste a Well Spent CSV export here')),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(child: const Text('Replace data'), onPressed: () async { final count = await provider.importCsv(controller.text); if (context.mounted) { Navigator.pop(context); showCupertinoDialog<void>(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('Import complete'), content: Text('$count entries imported.'), actions: [CupertinoDialogAction(child: const Text('Done'), onPressed: () => Navigator.pop(context))])); } }),
        ],
      ),
    );
    controller.dispose();
  }
}
