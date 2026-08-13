import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/message_transaction_service.dart';

class MessageImportScreen extends StatefulWidget {
  const MessageImportScreen({super.key});
  @override State<MessageImportScreen> createState() => _MessageImportScreenState();
}

class _MessageImportScreenState extends State<MessageImportScreen> {
  List<PendingTransaction> items = [];
  bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final found = await MessageTransactionService.instance.fetchPending(); if (mounted) setState(() { items = found; loading = false; }); }

  Future<void> _confirm(PendingTransaction item) async {
    final category = ExpenseCategory.values.firstWhere((e) => e.name == item.category, orElse: () => ExpenseCategory.other);
    await context.read<ExpenseProvider>().addExpense(Expense(title: item.title, amount: item.amount, category: category, date: item.date, note: item.note));
    await MessageTransactionService.instance.remove(item);
    if (mounted) setState(() => items.remove(item));
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review imports')),
    body: loading ? const Center(child: CircularProgressIndicator()) : items.isEmpty
      ? const Center(child: Text('No pending transactions'))
      : ListView.builder(itemCount: items.length, itemBuilder: (_, i) { final item = items[i]; return ListTile(
          title: Text(item.title), subtitle: Text('${item.source} · ${item.date.toLocal()}'),
          trailing: FilledButton(onPressed: () => _confirm(item), child: Text(item.amount.toStringAsFixed(2))),
        ); }),
  );
}
