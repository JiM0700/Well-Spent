import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

/// Cupertino-native add-expense modal. Uses CupertinoTextField,
/// CupertinoSlidingSegmentedControl, CupertinoDatePicker, and
/// CupertinoButton.filled — matching Apple first-party app patterns.
class QuickAddModal extends StatefulWidget {
  const QuickAddModal({super.key});

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  ExpenseType _selectedType = ExpenseType.expense;
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  ExpenseKind _selectedExpenseKind = ExpenseKind.variable;
  DateTime _selectedDate = DateTime.now();
  String? _titleError;
  String? _amountError;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
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

  bool _validate() {
    bool valid = true;
    setState(() {
      _titleError = null;
      _amountError = null;
      if (_titleController.text.trim().isEmpty) {
        _titleError = 'Enter a description';
        valid = false;
      }
      if (_amountController.text.trim().isEmpty) {
        _amountError = 'Enter an amount';
        valid = false;
      } else if (_evaluateExpression(_amountController.text.trim()) == null) {
        _amountError = 'Invalid amount or formula';
        valid = false;
      }
    });
    return valid;
  }

  void _submit() {
    if (!_validate()) return;

    final evaluatedAmount = _evaluateExpression(_amountController.text.trim())!;

    final expense = Expense(
      title: _titleController.text.trim(),
      amount: evaluatedAmount,
      category: _selectedCategory,
      date: _selectedDate,
      type: _selectedType,
      expenseKind: _selectedType == ExpenseType.expense ? _selectedExpenseKind : ExpenseKind.variable,
    );

    Provider.of<ExpenseProvider>(context, listen: false).addExpense(expense);
    Navigator.of(context).pop();
  }

  void _showDatePicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Done bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(2020),
                  onDateTimeChanged: (date) => setState(() => _selectedDate = date),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 12,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.separator.resolveFrom(context),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedType == ExpenseType.expense ? 'Add Expense' : 'Add Income',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    child: const Icon(CupertinoIcons.xmark_circle_fill, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type toggle
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<ExpenseType>(
                  groupValue: _selectedType,
                  children: const {
                    ExpenseType.expense: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Expense'),
                    ),
                    ExpenseType.income: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Income'),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Description field
              _fieldLabel('Description'),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _titleController,
                placeholder: 'What did you spend on?',
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                autofocus: true,
              ),
              if (_titleError != null) _errorText(_titleError!),
              const SizedBox(height: 16),

              // Amount field
              _fieldLabel('Amount (₹)'),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _amountController,
                placeholder: '0.00 or 15+3.50',
                keyboardType: TextInputType.text,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text('₹', style: TextStyle(color: secondaryLabel, fontSize: 17)),
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              if (_amountError != null) _errorText(_amountError!),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Supports math: 10 + 4.50',
                  style: TextStyle(fontSize: 12, color: secondaryLabel),
                ),
              ),
              const SizedBox(height: 20),

              // Category
              _fieldLabel('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? primaryColor : cardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? CupertinoColors.white
                              : labelColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Expense Kind (only for expenses)
              if (_selectedType == ExpenseType.expense) ...[
                _fieldLabel('Expense Kind'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<ExpenseKind>(
                    groupValue: _selectedExpenseKind,
                    children: const {
                      ExpenseKind.variable: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Variable'),
                      ),
                      ExpenseKind.fixed: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Fixed'),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _selectedExpenseKind = val);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Date
              _fieldLabel('Date'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.calendar, size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: TextStyle(fontSize: 15, color: labelColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Submit button
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: _submit,
                child: Text(
                  _selectedType == ExpenseType.expense ? 'Save Expense' : 'Save Income',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: CupertinoColors.systemRed.resolveFrom(context),
        ),
      ),
    );
  }
}
