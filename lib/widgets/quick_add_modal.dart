import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class QuickAddModal extends StatefulWidget {
  const QuickAddModal({super.key});

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  ExpenseType _selectedType = ExpenseType.expense;
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  ExpenseKind _selectedExpenseKind = ExpenseKind.variable;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _evaluateExpression(String input) {
    String clean = input.replaceAll(' ', '');
    if (clean.isEmpty) return null;

    try {
      if (clean.contains('+') || clean.contains('-')) {
        double total = 0.0;
        String currentNum = '';
        String currentOp = '+';

        for (int i = 0; i < clean.length; i++) {
          String char = clean[i];
          if (char == '+' || char == '-') {
            if (currentNum.isNotEmpty) {
              double val = double.parse(currentNum);
              total += (currentOp == '+') ? val : -val;
              currentNum = '';
            }
            currentOp = char;
          } else {
            currentNum += char;
          }
        }
        if (currentNum.isNotEmpty) {
          double val = double.parse(currentNum);
          total += (currentOp == '+') ? val : -val;
        }
        return total > 0 ? total : null;
      } else {
        final parsed = double.tryParse(clean);
        return (parsed != null && parsed > 0) ? parsed : null;
      }
    } catch (_) {
      return null;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final evaluatedAmount = _evaluateExpression(_amountController.text.trim());

      if (evaluatedAmount == null || evaluatedAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount or formula (e.g. 12 + 4.50)')),
        );
        return;
      }

      final expense = Expense(
        title: title,
        amount: evaluatedAmount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        type: _selectedType,
        expenseKind: _selectedType == ExpenseType.expense ? _selectedExpenseKind : ExpenseKind.variable,
      );

      Provider.of<ExpenseProvider>(context, listen: false).addExpense(expense);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedType == ExpenseType.expense ? 'Quick Add Expense' : 'Quick Add Income',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: ExpenseType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Description / Title',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a description' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Amount (₹) - e.g. 12.50 or 15+3.5',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                helperText: 'Supports math expressions like 10 + 4.50',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an amount';
                if (_evaluateExpression(v.trim()) == null) return 'Invalid calculation';
                return null;
              },
            ),
            const SizedBox(height: 16),

            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ExpenseCategory.values.map((cat) {
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: selected,
                  onSelected: (bool isSelected) {
                    if (isSelected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            if (_selectedType == ExpenseType.expense) ...[
              Text('Expense Kind', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ExpenseKind.values.map((kind) {
                  final selected = _selectedExpenseKind == kind;
                  return ChoiceChip(
                    label: Text(kind.displayName),
                    selected: selected,
                    onSelected: (bool isSelected) {
                      if (isSelected) setState(() => _selectedExpenseKind = kind);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _selectedType == ExpenseType.expense ? 'Save Expense' : 'Save Income',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
