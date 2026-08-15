import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/message_transaction_service.dart';
import '../widgets/forecast_card.dart';
import '../widgets/liquid_glass_chip.dart';
import '../widgets/liquid_glass_container.dart';
import '../widgets/quick_add_modal.dart';
import '../widgets/recurring_bills_card.dart';
import '../widgets/summary_card.dart';
import 'analytics_screen.dart';
import 'category_library_screen.dart';
import 'message_import_screen.dart';

/// Native macOS Desktop 26 Shell featuring Apple Split-View Liquid Glass Sidebar,
/// non-scrollable fixed viewport, independent scrollable feeds, and desktop shortcuts.
class MacosShellScreen extends StatefulWidget {
  const MacosShellScreen({super.key});

  @override
  State<MacosShellScreen> createState() => _MacosShellScreenState();
}

class _MacosShellScreenState extends State<MacosShellScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<PendingTransaction> _pendingTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadPendingMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingMessages() async {
    final pending = await MessageTransactionService.instance.fetchPending();
    if (mounted) setState(() => _pendingTransactions = pending);
  }

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            HardwareKeyboard.instance.isMetaPressed &&
            event.logicalKey == LogicalKeyboardKey.keyN) {
          _showAddExpenseModal(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: CupertinoPageScaffold(
        backgroundColor: isDark ? const Color(0xFF06080E) : const Color(0xFFF1F3F6),
        child: Row(
          children: [
            // ─── Left macOS Liquid Glass Sidebar ────────────────────────────────
            _buildSidebar(context, provider, isDark, primaryColor),

            // Vertical Hairline Divider
            Container(
              width: 0.8,
              color: isDark ? CupertinoColors.white.withValues(alpha: 0.1) : CupertinoColors.black.withValues(alpha: 0.08),
            ),

            // ─── Right macOS Content Area ──────────────────────────────────────
            Expanded(
              child: _buildMainPane(context, provider, isDark, primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, ExpenseProvider provider, bool isDark, Color primaryColor) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0A0E18) : const Color(0xFFF8FAFC)).withValues(alpha: 0.88),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Traffic light clearance & App branding
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 0.8),
                    ),
                    child: Icon(CupertinoIcons.creditcard_fill, size: 16, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Well Spent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: labelColor,
                        ),
                      ),
                      Text(
                        'Private · Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _sidebarItem(0, CupertinoIcons.house_fill, 'Overview', isDark, primaryColor),
                  _sidebarItem(1, CupertinoIcons.square_grid_2x2_fill, 'Categories', isDark, primaryColor),
                  _sidebarItem(2, CupertinoIcons.chart_bar_fill, 'Insights & Forecast', isDark, primaryColor),
                  _sidebarItem(
                    3,
                    CupertinoIcons.chat_bubble_2_fill,
                    'Messages Review',
                    isDark,
                    primaryColor,
                    badge: _pendingTransactions.isNotEmpty ? '${_pendingTransactions.length}' : null,
                  ),
                  _sidebarItem(4, CupertinoIcons.gear_alt_fill, 'Settings & Data', isDark, primaryColor),
                ],
              ),
            ),

            // Budget Glance in Sidebar Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: LiquidGlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(12),
                fillOpacity: 0.06,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CYCLE STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: secondaryLabel,
                          ),
                        ),
                        Text(
                          '${((provider.currentPeriodTotal / (provider.currentPeriodBudget > 0 ? provider.currentPeriodBudget : 1)) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 5,
                        child: LinearProgressIndicator(
                          value: (provider.currentPeriodBudget > 0)
                              ? (provider.currentPeriodTotal / provider.currentPeriodBudget).clamp(0.0, 1.0)
                              : 0.0,
                          backgroundColor: CupertinoColors.systemFill.resolveFrom(context),
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${provider.currentPeriodTotal.toStringAsFixed(0)} of ₹${provider.currentPeriodBudget.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: secondaryLabel, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Add Action in Sidebar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
                onPressed: () => _showAddExpenseModal(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.plus, size: 16, color: CupertinoColors.white),
                    SizedBox(width: 6),
                    Text(
                      'Log Entry (⌘N)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CupertinoColors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label, bool isDark, Color primaryColor, {String? badge}) {
    final isSelected = _selectedTabIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.15)
                : CupertinoColors.transparent,
            border: isSelected
                ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 0.8)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? primaryColor : (isDark ? CupertinoColors.white : CupertinoColors.label),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? CupertinoColors.white : primaryColor)
                        : (isDark ? CupertinoColors.white : CupertinoColors.label),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainPane(BuildContext context, ExpenseProvider provider, bool isDark, Color primaryColor) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDesktopOverview(context, provider, isDark, primaryColor);
      case 1:
        return Column(
          children: [
            _buildDesktopToolbar(context, provider, isDark, primaryColor, 'Category Library', showPeriodSwitcher: true),
            const Expanded(child: CategoryLibraryScreen(showNavigationBar: false)),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildDesktopToolbar(context, provider, isDark, primaryColor, 'Insights & Forecast', showPeriodSwitcher: true),
            const Expanded(child: AnalyticsScreen(showNavigationBar: false)),
          ],
        );
      case 3:
        return Column(
          children: [
            _buildDesktopToolbar(context, provider, isDark, primaryColor, 'Messages Review'),
            const Expanded(child: MessageImportScreen(showNavigationBar: false)),
          ],
        );
      case 4:
        return _buildDesktopSettings(context, provider, isDark, primaryColor);
      default:
        return _buildDesktopOverview(context, provider, isDark, primaryColor);
    }
  }

  Widget _buildDesktopToolbar(
    BuildContext context,
    ExpenseProvider provider,
    bool isDark,
    Color primaryColor,
    String title, {
    bool showPeriodSwitcher = false,
    bool showSearch = false,
  }) {
    final labelColor = CupertinoColors.label.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF090D16) : CupertinoColors.systemBackground).withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? CupertinoColors.white.withValues(alpha: 0.08) : CupertinoColors.black.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: labelColor,
            ),
          ),
          if (showPeriodSwitcher) ...[
            const SizedBox(width: 24),
            SizedBox(
              width: 260,
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: provider.viewMode,
                thumbColor: isDark ? const Color(0xFF1B2232) : CupertinoColors.white,
                children: const {
                  'weekly': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Text('Weekly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  'monthly': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Text('Monthly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  'yearly': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Text('Yearly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                },
                onValueChanged: (val) {
                  if (val != null) provider.updateViewMode(val);
                },
              ),
            ),
          ],
          const Spacer(),
          if (showSearch) ...[
            SizedBox(
              width: 220,
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Filter activity…',
                style: TextStyle(fontSize: 13, color: labelColor),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopOverview(BuildContext context, ExpenseProvider provider, bool isDark, Color primaryColor) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    final filteredExpenses = provider.expenses.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildDesktopToolbar(
          context,
          provider,
          isDark,
          primaryColor,
          '${provider.currentPeriodLabel} Overview',
          showPeriodSwitcher: true,
          showSearch: true,
        ),

        // 2-Column Fixed Desktop Viewport with Independent Internal Scrolling
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── LEFT PANE: Fixed Glance & Forecast (Scrolls vertically if small screen) ──
                SizedBox(
                  width: 380,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
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
                      ForecastCard(forecast: provider.forecast),
                      const SizedBox(height: 16),
                      const RecurringBillsCard(),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // ── RIGHT PANE: Flex 1 Activity Feed (100% Height Locked & Scrollable) ──────
                Expanded(
                  child: LiquidGlassContainer(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    fillOpacity: 0.06,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: labelColor,
                              ),
                            ),
                            Text(
                              '${filteredExpenses.length} entries',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryLabel),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Category Filter Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              LiquidGlassChip(
                                label: 'All',
                                isSelected: provider.selectedCategoryFilter == null,
                                onPressed: () => provider.filterByCategory(null),
                              ),
                              const SizedBox(width: 6),
                              ...ExpenseCategory.values.map((cat) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
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

                        // Scrollable List of Transactions
                        Expanded(
                          child: filteredExpenses.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.doc_text, size: 40, color: secondaryLabel),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No transactions found',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: secondaryLabel),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredExpenses.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredExpenses[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: LiquidGlassContainer(
                                        borderRadius: 14,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        fillOpacity: 0.04,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: (item.isIncome ? primaryColor : CupertinoColors.activeBlue)
                                                    .withValues(alpha: 0.16),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                _getCategoryIcon(item.category),
                                                size: 16,
                                                color: item.isIncome ? primaryColor : CupertinoColors.activeBlue,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor),
                                                  ),
                                                  Text(
                                                    '${item.category.displayName} · ${DateFormat('MMM d, yyyy').format(item.date)}',
                                                    style: TextStyle(fontSize: 12, color: secondaryLabel),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${item.isIncome ? '+' : '-'}₹${item.amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: item.isIncome ? primaryColor : labelColor,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              onPressed: () {
                                                if (item.id != null) provider.deleteExpense(item.id!);
                                              },
                                              child: Icon(CupertinoIcons.trash, size: 14, color: secondaryLabel),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSettings(BuildContext context, ExpenseProvider provider, bool isDark, Color primaryColor) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text('Preferences & Cycle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CupertinoColors.label.resolveFrom(context))),
            const SizedBox(height: 20),
            LiquidGlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _settingRow('Monthly Budget', '₹${provider.monthlyBudget.toStringAsFixed(0)}', () => _showSetBudgetDialog(context, provider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(height: 0.8, color: CupertinoColors.separator.resolveFrom(context)),
                  ),
                  _settingRow('Cycle Start Day', 'Day ${provider.cycleStartDay}', () => _editCycleDay(context, provider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(height: 0.8, color: CupertinoColors.separator.resolveFrom(context)),
                  ),
                  _settingRow('Base Monthly Income', '₹${provider.baseMonthlyIncome.toStringAsFixed(0)}', () => _editIncome(context, provider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(height: 0.8, color: CupertinoColors.separator.resolveFrom(context)),
                  ),
                  _settingRow('Payday', 'Day ${provider.payDay}', () => _editPayday(context, provider)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingRow(String title, String value, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  static Future<void> _editCycleDay(BuildContext context, ExpenseProvider provider) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Cycle starts on'),
        actions: [1, 5, 10, 15, 20, 25]
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
  }

  static Future<void> _editPayday(BuildContext context, ExpenseProvider provider) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Payday'),
        actions: [1, 5, 10, 15, 20, 25, 28, 30]
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
}
