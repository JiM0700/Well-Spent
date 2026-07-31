import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'analytics_screen.dart';
import 'category_library_screen.dart';
import 'dashboard_screen.dart';
import '../providers/expense_provider.dart';

/// Standard Apple tab-bar shell — identical pattern to Apple's first-party
/// apps (Wallet, Health, Stocks). Four tabs with the system tab bar at the
/// bottom; "Add" lives in the navigation bar of each screen.
class IosShellScreen extends StatelessWidget {
  const IosShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_fill),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear_alt_fill),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0:
                return const DashboardScreen();
              case 1:
                return const CategoryLibraryScreen();
              case 2:
                return const AnalyticsScreen();
              case 3:
                return const _IosSettingsScreen();
              default:
                return const DashboardScreen();
            }
          },
        );
      },
    );
  }
}

// ─── Settings ───────────────────────────────────────────────────────────────

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
            _sectionHeader(context, 'BUDGETING'),
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
                  additionalInfo: Text('Day ${provider.cycleStartDay}'),
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
            _sectionHeader(context, 'SUMMARIES'),
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
            _sectionHeader(context, 'ABOUT'),
            CupertinoListSection.insetGrouped(
              children: const [
                CupertinoListTile(
                  title: Text('Well Spent'),
                  additionalInfo: Text('Offline-first'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Text('₹ ')),
          ),
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) provider.updateMonthlyBudget(value);
              Navigator.pop(context);
            },
          ),
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
        actions: [5, 10, 15, 20, 25, 1]
            .map((day) => CupertinoActionSheetAction(
                  onPressed: () {
                    provider.updateCycleStartDay(day);
                    Navigator.pop(context);
                  },
                  child: Text('Day $day'),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static Future<void> _editIncome(BuildContext context, ExpenseProvider provider) async {
    final controller = TextEditingController(text: provider.baseMonthlyIncome.toStringAsFixed(0));
    await showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Monthly income'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Text('₹ ')),
          ),
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) provider.updateBaseMonthlyIncome(value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    controller.dispose();
  }

  static Future<void> _editPayday(BuildContext context, ExpenseProvider provider) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Payday'),
        actions: List.generate(31, (index) => index + 1)
            .map((day) => CupertinoActionSheetAction(
                  onPressed: () {
                    provider.updatePayDay(day);
                    Navigator.pop(context);
                  },
                  child: Text('Day $day'),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static Future<void> _choosePeriod(BuildContext context, ExpenseProvider provider) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Summary period'),
        actions: {'daily': 'Today', 'weekly': 'Last 7 days', 'monthly': 'This month'}
            .entries
            .map((entry) => CupertinoActionSheetAction(
                  onPressed: () {
                    provider.updateSummaryPeriod(entry.key);
                    Navigator.pop(context);
                  },
                  child: Text(entry.value),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static Future<void> _exportCsv(BuildContext context, ExpenseProvider provider) async {
    await Clipboard.setData(ClipboardData(text: provider.exportCsv()));
    if (context.mounted) {
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('CSV copied'),
          content: const Text(
              'Your data was copied as CSV. Paste it into a file or spreadsheet to save a backup.'),
          actions: [
            CupertinoDialogAction(child: const Text('Done'), onPressed: () => Navigator.pop(context)),
          ],
        ),
      );
    }
  }

  static Future<void> _importCsv(BuildContext context, ExpenseProvider provider) async {
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
}
