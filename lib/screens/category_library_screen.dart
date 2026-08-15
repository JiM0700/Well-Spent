import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/liquid_glass_container.dart';
import 'package:provider/provider.dart';

/// Apple-native category library using Liquid Glass cards (iOS / macOS 26 style).
class CategoryLibraryScreen extends StatelessWidget {
  const CategoryLibraryScreen({super.key});

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
    final labelColor = CupertinoColors.label.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF07090E) : const Color(0xFFF2F4F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDark ? const Color(0xFF0B0F18) : CupertinoColors.systemBackground).withValues(alpha: 0.85),
        middle: const Text('Categories', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      child: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: ExpenseCategory.values.length,
          itemBuilder: (context, index) {
            final category = ExpenseCategory.values[index];
            final amount = provider.categoryBreakdown[category] ?? 0;

            return LiquidGlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              fillOpacity: 0.08,
              onTap: () => _showCategoryDetails(context, category, provider),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon(category), size: 20, color: primaryColor),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCategoryDetails(BuildContext context, ExpenseCategory category, ExpenseProvider provider) {
    final expenses = provider.expenses.where((e) => e.category == category && e.isExpense).toList();
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(category.displayName),
        message: Text('Total spent: ₹${total.toStringAsFixed(2)} across ${expenses.length} entries'),
        actions: [
          ...expenses.take(5).map((e) => CupertinoActionSheetAction(
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
}
