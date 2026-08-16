import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'liquid_glass_container.dart';

class RecurringBillsCard extends StatelessWidget {
  const RecurringBillsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final warningColor = CupertinoColors.systemOrange.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    final bills = provider.recurringBills;
    final range = provider.currentPeriodRange;
    final now = DateTime.now();

    return LiquidGlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      fillOpacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(CupertinoIcons.calendar_badge_plus, size: 17, color: primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recurring Bills & Subs',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Upcoming: ₹${provider.upcomingBillsTotal.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: secondaryLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _showAddBillDialog(context, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.plus, size: 12, color: primaryColor),
                      const SizedBox(width: 3),
                      Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No recurring bills added yet. Track Netflix, Rent, Wi-Fi & utilities.',
                  style: TextStyle(fontSize: 12, color: secondaryLabel),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...bills.map((bill) {
              final isPaid = bill.isPaidForCycle(range.startDate, range.endDate);
              final daysLeft = bill.daysUntilDue(now);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? CupertinoColors.white.withValues(alpha: 0.04) : CupertinoColors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? CupertinoColors.white.withValues(alpha: 0.06) : CupertinoColors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    bill.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: labelColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? primaryColor.withValues(alpha: 0.16)
                                        : (daysLeft <= 3 ? warningColor.withValues(alpha: 0.16) : (isDark ? CupertinoColors.white.withValues(alpha: 0.08) : CupertinoColors.black.withValues(alpha: 0.05))),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPaid
                                        ? 'Paid ✅'
                                        : (daysLeft == 0 ? 'Due Today ⚠️' : '${daysLeft}d left'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isPaid ? primaryColor : (daysLeft <= 3 ? warningColor : secondaryLabel),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Day ${bill.dueDay} · ${bill.category.displayName}',
                              style: TextStyle(fontSize: 11, color: secondaryLabel),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${bill.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isPaid)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => provider.markBillPaid(bill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              'Pay',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF041407),
                              ),
                            ),
                          ),
                        )
                      else
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => provider.deleteRecurringBill(bill.id),
                          child: Icon(CupertinoIcons.trash, size: 15, color: secondaryLabel),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddBillDialog(BuildContext context, ExpenseProvider provider) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final dayController = TextEditingController(text: '5');
    ExpenseCategory selectedCat = ExpenseCategory.bills;

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('Add Recurring Bill / Sub'),
          content: Column(
            children: [
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: titleController,
                placeholder: 'e.g. Netflix, House Rent, Wi-Fi',
                autofocus: true,
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                placeholder: 'Amount (₹)',
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                placeholder: 'Due Day of Month (1 - 31)',
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final title = titleController.text.trim();
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                final day = int.tryParse(dayController.text.trim()) ?? 1;

                if (title.isNotEmpty && amt > 0) {
                  provider.addRecurringBill(
                    RecurringBill(
                      id: DateTime.now().millisecondsSinceEpoch,
                      title: title,
                      amount: amt,
                      category: selectedCat,
                      dueDay: day.clamp(1, 31),
                    ),
                  );
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
