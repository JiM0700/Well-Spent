import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'analytics_screen.dart';
import 'category_library_screen.dart';
import 'dashboard_screen.dart';
import '../providers/expense_provider.dart';
import '../widgets/quick_add_modal.dart';

/// Apple Next-Gen Dual-Island Navigation:
/// - Floating Glass Capsule Tab Bar (Overview, Categories, Insights, Settings) with active pill highlight
/// - Detached Floating Glass Circular Add (+) Action Button
class IosShellScreen extends StatefulWidget {
  const IosShellScreen({super.key});

  @override
  State<IosShellScreen> createState() => _IosShellScreenState();
}

class _IosShellScreenState extends State<IosShellScreen> {
  int _currentTab = 0;

  void _showAddExpenseModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const QuickAddModal(),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color primaryColor,
    required Color labelColor,
    required Color secondaryLabel,
    required bool isDark,
  }) {
    final isSelected = _currentTab == index;

    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            setState(() => _currentTab = index);
          }
        },
        child: SizedBox(
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Active pill bubble highlight matching Swift: cornerRadius 100, UIColor(0.929, 0.929, 0.929, 1)
              if (isSelected)
                Positioned(
                  left: -2,
                  right: -2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: isDark
                          ? const Color(0xFF2C3446)
                          : const Color.fromRGBO(237, 237, 237, 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

              // Content View: Icon + Label centered
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      size: 21,
                      color: isSelected
                          ? primaryColor
                          : (isDark ? CupertinoColors.white.withValues(alpha: 0.85) : const Color(0xFF1C1C1E)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? primaryColor
                          : (isDark ? CupertinoColors.white.withValues(alpha: 0.85) : const Color(0xFF1C1C1E)),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = 62.0 + (bottomInset > 0 ? bottomInset : 14.0);

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF07090E) : const Color(0xFFF2F4F7),
      child: Stack(
        children: [
          // ── Screen View Content ───────────────────────────────────
          Positioned.fill(
            child: IndexedStack(
              index: _currentTab,
              children: const [
                DashboardScreen(),
                CategoryLibraryScreen(),
                AnalyticsScreen(),
                _IosSettingsScreen(),
              ],
            ),
          ),

          // ── Apple 95pt Bottom Dock Bar (view.bottomAnchor == parent.bottomAnchor) ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: Container(
              padding: EdgeInsets.fromLTRB(14, 4, 14, bottomInset > 0 ? bottomInset : 6),
              alignment: Alignment.topCenter,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Tab Bar Capsule Island (Height: 62) ───────────────────
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          height: 62,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: (isDark ? const Color(0xFF131826) : const Color(0xFFF6F8FA))
                                .withValues(alpha: isDark ? 0.88 : 0.94),
                            border: Border.all(
                              color: isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.16)
                                  : CupertinoColors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildTabItem(
                                index: 0,
                                icon: CupertinoIcons.house,
                                activeIcon: CupertinoIcons.house_fill,
                                label: 'Overview',
                                primaryColor: primaryColor,
                                labelColor: labelColor,
                                secondaryLabel: secondaryLabel,
                                isDark: isDark,
                              ),
                              _buildTabItem(
                                index: 1,
                                icon: CupertinoIcons.square_grid_2x2,
                                activeIcon: CupertinoIcons.square_grid_2x2_fill,
                                label: 'Categories',
                                primaryColor: primaryColor,
                                labelColor: labelColor,
                                secondaryLabel: secondaryLabel,
                                isDark: isDark,
                              ),
                              _buildTabItem(
                                index: 2,
                                icon: CupertinoIcons.chart_bar,
                                activeIcon: CupertinoIcons.chart_bar_fill,
                                label: 'Insights',
                                primaryColor: primaryColor,
                                labelColor: labelColor,
                                secondaryLabel: secondaryLabel,
                                isDark: isDark,
                              ),
                              _buildTabItem(
                                index: 3,
                                icon: CupertinoIcons.gear_alt,
                                activeIcon: CupertinoIcons.gear_alt_fill,
                                label: 'Settings',
                                primaryColor: primaryColor,
                                labelColor: labelColor,
                                secondaryLabel: secondaryLabel,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ── Detached Floating Action Pod Island (Height: 62, Width: 62) ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: (isDark ? const Color(0xFF131826) : const Color(0xFFF6F8FA))
                              .withValues(alpha: isDark ? 0.88 : 0.94),
                          border: Border.all(
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.16)
                                : CupertinoColors.black.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showAddExpenseModal(context),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C3446)
                                  : const Color.fromRGBO(237, 237, 237, 1.0),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(CupertinoIcons.plus, size: 22, color: primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings ───────────────────────────────────────────────────────────────

class _IosSettingsScreen extends StatelessWidget {
  const _IosSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF06080E) : const Color(0xFFF1F3F6),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Settings',
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
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),
              _sectionHeader(context, 'BUDGETING'),
              CupertinoListSection.insetGrouped(
                children: [
                  CupertinoListTile(
                    title: const Text('Export CSV'),
                    leading: const Icon(CupertinoIcons.arrow_up_doc),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _exportCsv(context, provider);
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Import CSV'),
                    leading: const Icon(CupertinoIcons.arrow_down_doc),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _importCsv(context, provider);
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Monthly budget'),
                    additionalInfo: Text('₹${provider.monthlyBudget.toStringAsFixed(0)}'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _editBudget(context, provider);
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Cycle starts on'),
                    additionalInfo: Text('Day ${provider.cycleStartDay}'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _editCycleDay(context, provider);
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Monthly income'),
                    additionalInfo: Text('₹${provider.baseMonthlyIncome.toStringAsFixed(0)}'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _editIncome(context, provider);
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Payday'),
                    additionalInfo: Text('Day ${provider.payDay}'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _editPayday(context, provider);
                    },
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
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        provider.updateSummaryEnabled(val);
                      },
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Summary period'),
                    additionalInfo: Text(_periodLabel(provider.summaryPeriod)),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _choosePeriod(context, provider);
                    },
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
              const SizedBox(height: 90),
            ]),
          ),
        ],
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
