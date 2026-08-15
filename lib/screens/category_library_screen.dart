import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/liquid_glass_container.dart';

/// Apple-native category library with responsive Liquid Glass Budget Envelopes.
/// Features full-width spacious cards on mobile (iPhone) and adaptive grid on desktop/iPad.
class CategoryLibraryScreen extends StatelessWidget {
  final bool showNavigationBar;

  const CategoryLibraryScreen({
    super.key,
    this.showNavigationBar = true,
  });

  IconData _icon(ExpenseCategory category) {
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
    final provider = context.watch<ExpenseProvider>();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final warningColor = CupertinoColors.systemOrange.resolveFrom(context);
    final dangerColor = CupertinoColors.systemRed.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (showNavigationBar)
              CupertinoSliverNavigationBar(
                largeTitle: const Text(
                  'Categories',
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
                    '${provider.currentPeriodLabel} Cycle',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: secondaryLabel,
                    ),
                  ),
                ),
              ),

            // Top instructions & context banner
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? CupertinoColors.white.withValues(alpha: 0.04) : CupertinoColors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? CupertinoColors.white.withValues(alpha: 0.06) : CupertinoColors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.info_circle_fill, size: 16, color: primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tap any category to set its budget target or inspect entries.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Adaptive Content: 1-Column List on Mobile / Multi-Column Grid on Tablet/Desktop
            if (isMobile)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = ExpenseCategory.values[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMobileEnvelopeCard(
                          context,
                          category,
                          provider,
                          isDark,
                          primaryColor,
                          warningColor,
                          dangerColor,
                          labelColor,
                          secondaryLabel,
                        ),
                      );
                    },
                    childCount: ExpenseCategory.values.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: (constraints.maxWidth / 260).floor().clamp(2, 5),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 155,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = ExpenseCategory.values[index];
                      return _buildGridEnvelopeCard(
                        context,
                        category,
                        provider,
                        isDark,
                        primaryColor,
                        warningColor,
                        dangerColor,
                        labelColor,
                        secondaryLabel,
                      );
                    },
                    childCount: ExpenseCategory.values.length,
                  ),
                ),
              ),
          ],
        );
      },
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

  /// Mobile full-width envelope card (optimized for iPhone ergonomics & legibility)
  Widget _buildMobileEnvelopeCard(
    BuildContext context,
    ExpenseCategory category,
    ExpenseProvider provider,
    bool isDark,
    Color primaryColor,
    Color warningColor,
    Color dangerColor,
    Color labelColor,
    Color secondaryLabel,
  ) {
    final amount = provider.categoryBreakdown[category] ?? 0;
    final budget = provider.getCategoryBudget(category);
    final categoryExpenses = provider.expenses.where((e) => e.category == category && e.isExpense).toList();
    final count = categoryExpenses.length;

    final hasBudget = budget > 0;
    final progress = hasBudget ? (amount / budget) : (provider.currentPeriodTotal > 0 ? (amount / provider.currentPeriodTotal) : 0.0);
    final isOver = hasBudget && amount > budget;
    final isWarning = hasBudget && amount >= budget * 0.8 && !isOver;
    final barColor = isOver ? dangerColor : (isWarning ? warningColor : primaryColor);

    return LiquidGlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      fillOpacity: 0.08,
      onTap: () => _showCategoryDetails(context, category, provider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icon(category), size: 19, color: barColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: labelColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasBudget) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isOver
                                  ? dangerColor.withValues(alpha: 0.18)
                                  : (isWarning ? warningColor.withValues(alpha: 0.18) : primaryColor.withValues(alpha: 0.14)),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isOver
                                  ? 'Over ₹${(amount - budget).toStringAsFixed(0)}'
                                  : '₹${(budget - amount).toStringAsFixed(0)} left',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: barColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'entry' : 'entries'} · ${hasBudget ? 'Target ₹${budget.toStringAsFixed(0)}' : 'No target set'}',
                      style: TextStyle(fontSize: 12, color: secondaryLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: labelColor,
                    ),
                  ),
                  Text(
                    hasBudget ? '${(progress * 100).toStringAsFixed(0)}%' : '${(progress * 100).toStringAsFixed(0)}% total',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.08)
                    : CupertinoColors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop/iPad grid envelope card
  Widget _buildGridEnvelopeCard(
    BuildContext context,
    ExpenseCategory category,
    ExpenseProvider provider,
    bool isDark,
    Color primaryColor,
    Color warningColor,
    Color dangerColor,
    Color labelColor,
    Color secondaryLabel,
  ) {
    final amount = provider.categoryBreakdown[category] ?? 0;
    final budget = provider.getCategoryBudget(category);
    final categoryExpenses = provider.expenses.where((e) => e.category == category && e.isExpense).toList();
    final count = categoryExpenses.length;

    final hasBudget = budget > 0;
    final progress = hasBudget ? (amount / budget) : (provider.currentPeriodTotal > 0 ? (amount / provider.currentPeriodTotal) : 0.0);
    final isOver = hasBudget && amount > budget;
    final isWarning = hasBudget && amount >= budget * 0.8 && !isOver;
    final barColor = isOver ? dangerColor : (isWarning ? warningColor : primaryColor);

    return LiquidGlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      fillOpacity: 0.08,
      onTap: () => _showCategoryDetails(context, category, provider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon(category), size: 17, color: barColor),
              ),
              if (hasBudget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOver
                        ? dangerColor.withValues(alpha: 0.18)
                        : (isWarning ? warningColor.withValues(alpha: 0.18) : primaryColor.withValues(alpha: 0.14)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isOver
                        ? 'Over ₹${(amount - budget).toStringAsFixed(0)}'
                        : '₹${(budget - amount).toStringAsFixed(0)} left',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: barColor,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? CupertinoColors.white.withValues(alpha: 0.08) : CupertinoColors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$count ${count == 1 ? 'entry' : 'entries'}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: secondaryLabel),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            category.displayName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryLabel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: labelColor,
                ),
              ),
              Text(
                hasBudget ? 'of ₹${budget.toStringAsFixed(0)}' : '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: isDark ? CupertinoColors.white.withValues(alpha: 0.08) : CupertinoColors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(BuildContext context, ExpenseCategory category, ExpenseProvider provider) {
    final expenses = provider.expenses.where((e) => e.category == category && e.isExpense).toList();
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final currentBudget = provider.getCategoryBudget(category);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(category.displayName),
        message: Text(
          'Total spent: ₹${total.toStringAsFixed(2)} across ${expenses.length} entries'
          '${currentBudget > 0 ? '\nBudget Envelope: ₹${currentBudget.toStringAsFixed(0)}' : '\nNo category envelope set'}',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showEditCategoryBudgetDialog(context, category, provider, currentBudget);
            },
            child: Text(currentBudget > 0 ? '✏️ Edit Envelope Target' : '🎯 Set Category Budget Envelope'),
          ),
          ...expenses.take(8).map((e) => CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: Text('${e.title} — ₹${e.amount.toStringAsFixed(2)} (${DateFormat('MMM d').format(e.date)})'),
              )),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ),
    );
  }

  void _showEditCategoryBudgetDialog(
    BuildContext context,
    ExpenseCategory category,
    ExpenseProvider provider,
    double currentBudget,
  ) {
    final textController = TextEditingController(text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '');

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: Text('Set ${category.displayName} Budget'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text('Enter target budget limit for this category (₹):'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: textController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'e.g. 5000',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.updateCategoryBudget(category, 0);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Clear Target'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final val = double.tryParse(textController.text.trim()) ?? 0.0;
              provider.updateCategoryBudget(category, val);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
