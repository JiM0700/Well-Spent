import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'package:provider/provider.dart';

class CategoryLibraryScreen extends StatelessWidget {
  const CategoryLibraryScreen({super.key});

  IconData _icon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food: return CupertinoIcons.shopping_cart;
      case ExpenseCategory.transport: return CupertinoIcons.car_detailed;
      case ExpenseCategory.bills: return CupertinoIcons.doc_text;
      case ExpenseCategory.shopping: return CupertinoIcons.bag;
      case ExpenseCategory.healthcare: return CupertinoIcons.heart;
      case ExpenseCategory.entertainment: return CupertinoIcons.film;
      case ExpenseCategory.invest: return CupertinoIcons.chart_bar_alt_fill;
      case ExpenseCategory.other: return CupertinoIcons.ellipsis;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    return Scaffold(
      appBar: (defaultTargetPlatform == TargetPlatform.iOS
          ? const CupertinoNavigationBar(middle: Text('Categories'))
          : AppBar(title: const Text('Categories'))) as PreferredSizeWidget,
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(category: category),
              )),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(_icon(category), size: 28, color: Theme.of(context).colorScheme.primary),
                    Text(category.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('₹${amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final ExpenseCategory category;
  const CategoryDetailScreen({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final items = provider.allExpenses.where((e) => e.category == category).toList();
    final total = items.fold<double>(0, (sum, item) => sum + (item.isExpense ? item.amount : -item.amount));
    return Scaffold(
      appBar: (defaultTargetPlatform == TargetPlatform.iOS
          ? CupertinoNavigationBar(middle: Text(category.displayName))
          : AppBar(title: Text(category.displayName))) as PreferredSizeWidget,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('This period', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text('₹${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('${items.length} transaction${items.length == 1 ? '' : 's'}'),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No transactions in this category yet.')))
          else
            ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.date.toLocal().toString().split(' ').first),
                trailing: Text('${item.isIncome ? '+' : '-'}₹${item.amount.toStringAsFixed(2)}'),
              ),
            )),
        ],
      ),
    );
  }
}
