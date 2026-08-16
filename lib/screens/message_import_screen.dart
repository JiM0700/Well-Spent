import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/message_transaction_service.dart';
import '../widgets/liquid_glass_container.dart';

class MessageImportScreen extends StatefulWidget {
  final bool showNavigationBar;

  const MessageImportScreen({
    super.key,
    this.showNavigationBar = true,
  });

  @override
  State<MessageImportScreen> createState() => _MessageImportScreenState();
}

class _MessageImportScreenState extends State<MessageImportScreen> {
  List<PendingTransaction> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final found = await MessageTransactionService.instance.fetchPending();
    if (mounted) setState(() { items = found; loading = false; });
  }

  Future<void> _confirm(PendingTransaction item) async {
    final category = ExpenseCategory.values.firstWhere(
      (e) => e.name == item.category,
      orElse: () => ExpenseCategory.other,
    );
    await context.read<ExpenseProvider>().addExpense(
      Expense(
        title: item.title,
        amount: item.amount,
        category: category,
        date: item.date,
        note: item.note,
      ),
    );
    await MessageTransactionService.instance.remove(item);
    if (mounted) setState(() => items.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    Widget content = loading
        ? const Center(child: CupertinoActivityIndicator(radius: 14))
        : items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.chat_bubble_2, size: 48, color: secondaryLabel),
                    const SizedBox(height: 12),
                    Text(
                      'No pending transactions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: labelColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transactions detected in Messages will appear here.',
                      style: TextStyle(fontSize: 13, color: secondaryLabel),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      fillOpacity: 0.08,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(CupertinoIcons.chat_bubble_text_fill, size: 18, color: primaryColor),
                          ),
                          const SizedBox(width: 14),
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
                                  '${item.source} · ${DateFormat('MMM d, h:mm a').format(item.date.toLocal())}',
                                  style: TextStyle(fontSize: 12, color: secondaryLabel),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () => _confirm(item),
                            child: Text(
                              '+ ₹${item.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );

    if (!widget.showNavigationBar) {
      return Container(
        color: isDark ? const Color(0xFF06080E) : const Color(0xFFF1F3F6),
        child: content,
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF06080E) : const Color(0xFFF1F3F6),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDark ? const Color(0xFF0A0E18) : CupertinoColors.systemBackground).withValues(alpha: 0.85),
        middle: const Text('Review SMS Transactions', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      child: SafeArea(child: content),
    );
  }
}
