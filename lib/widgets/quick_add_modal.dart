import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'liquid_glass_chip.dart';
import 'liquid_glass_container.dart';

/// Apple-native Liquid Glass Quick Add Modal (iOS / macOS 26 style).
/// Features real-time formula evaluation, tactile category chips,
/// quick date selectors, and smooth haptics.
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

  double? _evaluatedAmount;
  String? _amountError;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _evaluatedAmount = null;
        _amountError = null;
      });
      return;
    }
    final parsed = _evaluateExpression(text);
    setState(() {
      _evaluatedAmount = parsed;
      _amountError = (parsed == null || parsed <= 0) ? 'Invalid formula' : null;
    });
  }

  double? _evaluateExpression(String input) {
    final str = input.trim();
    if (str.isEmpty || RegExp(r'[^0-9.+\-*/()\s]').hasMatch(str)) return null;

    int pos = 0;
    String? peek() {
      while (pos < str.length && str[pos] == ' ') {
        pos++;
      }
      return pos < str.length ? str[pos] : null;
    }

    late double Function() parsePrimary;
    late double Function() parseMulDiv;
    late double Function() parseAddSub;

    parsePrimary = () {
      final ch = peek();
      if (ch == null) throw Exception('Unexpected end');
      if (ch == '(') {
        pos++;
        final val = parseAddSub();
        if (peek() != ')') throw Exception('Expected )');
        pos++;
        return val;
      }
      if (ch == '+' || ch == '-') {
        pos++;
        final val = parsePrimary();
        return ch == '+' ? val : -val;
      }
      final start = pos;
      while (pos < str.length && RegExp(r'[0-9.]').hasMatch(str[pos])) {
        pos++;
      }
      if (start == pos) throw Exception('Expected number');
      final numStr = str.substring(start, pos);
      final numVal = double.tryParse(numStr);
      if (numVal == null) throw Exception('Invalid number');
      return numVal;
    };

    parseMulDiv = () {
      double left = parsePrimary();
      while (true) {
        final ch = peek();
        if (ch == '*' || ch == '/') {
          pos++;
          final right = parsePrimary();
          if (ch == '*') {
            left *= right;
          } else {
            if (right == 0) throw Exception('Division by zero');
            left /= right;
          }
        } else {
          break;
        }
      }
      return left;
    };

    parseAddSub = () {
      double left = parseMulDiv();
      while (true) {
        final ch = peek();
        if (ch == '+' || ch == '-') {
          pos++;
          final right = parseMulDiv();
          if (ch == '+') {
            left += right;
          } else {
            left -= right;
          }
        } else {
          break;
        }
      }
      return left;
    };

    try {
      final result = parseAddSub();
      return pos == str.length ? result : null;
    } catch (_) {
      return null;
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = _evaluatedAmount ?? _evaluateExpression(_amountController.text.trim());

    bool hasErr = false;
    if (title.isEmpty) {
      setState(() => _titleError = 'Description is required');
      hasErr = true;
    } else {
      setState(() => _titleError = null);
    }

    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid amount or formula');
      hasErr = true;
    } else {
      setState(() => _amountError = null);
    }

    if (hasErr) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.mediumImpact();
    final expense = Expense(
      title: title,
      amount: amount!,
      category: _selectedType == ExpenseType.income ? ExpenseCategory.invest : _selectedCategory,
      date: _selectedDate,
      type: _selectedType,
      expenseKind: _selectedExpenseKind,
    );

    context.read<ExpenseProvider>().addExpense(expense);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final accentGreen = CupertinoColors.systemGreen.resolveFrom(context);

    final envBudget = provider.getCategoryBudget(_selectedCategory);
    final currentCatSpent = provider.categoryBreakdown[_selectedCategory] ?? 0.0;
    final entersAmount = _evaluatedAmount ?? double.tryParse(_amountController.text.trim()) ?? 0.0;
    final isOverEnvelope = _selectedType == ExpenseType.expense && envBudget > 0 && entersAmount > 0 && (currentCatSpent + entersAmount > envBudget);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F141E).withValues(alpha: 0.92)
                : CupertinoColors.systemGroupedBackground.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.2)
                    : CupertinoColors.black.withValues(alpha: 0.1),
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.25)
                            : CupertinoColors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedType == ExpenseType.expense ? 'Quick Add Expense' : 'Quick Add Income',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: isDark ? CupertinoColors.white : CupertinoColors.label,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.1)
                                : CupertinoColors.black.withValues(alpha: 0.06),
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 14,
                            color: isDark ? CupertinoColors.white : CupertinoColors.label,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Segmented Switcher (Expense / Income)
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<ExpenseType>(
                      groupValue: _selectedType,
                      backgroundColor: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.08)
                          : CupertinoColors.black.withValues(alpha: 0.05),
                      thumbColor: isDark
                          ? const Color(0xFF1E2638)
                          : CupertinoColors.white,
                      children: {
                        ExpenseType.expense: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedType == ExpenseType.expense
                                  ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                                  : CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ),
                        ExpenseType.income: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedType == ExpenseType.income
                                  ? accentGreen
                                  : CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedType = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Field & Formula Preview
                  LiquidGlassContainer(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 16,
                    fillOpacity: 0.05,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _selectedType == ExpenseType.income
                                    ? accentGreen
                                    : (isDark ? CupertinoColors.white : CupertinoColors.black),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CupertinoTextField(
                                controller: _amountController,
                                placeholder: '0.00 or 150 + 40',
                                keyboardType: TextInputType.text,
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                ),
                                decoration: null,
                                placeholderStyle: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.placeholderText.resolveFrom(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_evaluatedAmount != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accentGreen.withValues(alpha: 0.3), width: 0.8),
                            ),
                            child: Text(
                              '= ₹${_evaluatedAmount!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accentGreen,
                              ),
                            ),
                          ),
                        ],
                        if (_amountError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _amountError!,
                            style: const TextStyle(fontSize: 12, color: CupertinoColors.systemRed),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description Field
                  LiquidGlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    borderRadius: 16,
                    fillOpacity: 0.05,
                    child: CupertinoTextField(
                      controller: _titleController,
                      placeholder: 'Description (e.g. Groceries, Dinner)',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                      decoration: null,
                      placeholderStyle: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.placeholderText.resolveFrom(context),
                      ),
                    ),
                  ),
                  if (_titleError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 6),
                      child: Text(
                        _titleError!,
                        style: const TextStyle(fontSize: 12, color: CupertinoColors.systemRed),
                      ),
                    ),
                  const SizedBox(height: 18),

                  // Categories (if Expense)
                  if (_selectedType == ExpenseType.expense) ...[
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategory.values.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return LiquidGlassChip(
                          label: cat.displayName,
                          isSelected: isSelected,
                          onPressed: () => setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Expense Kind (Variable / Fixed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EXPENSE TYPE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                        CupertinoSlidingSegmentedControl<ExpenseKind>(
                          groupValue: _selectedExpenseKind,
                          thumbColor: isDark
                              ? const Color(0xFF1E2638)
                              : CupertinoColors.white,
                          children: const {
                            ExpenseKind.variable: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Text('Variable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            ExpenseKind.fixed: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Text('Fixed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          },
                          onValueChanged: (val) {
                            if (val != null) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedExpenseKind = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Date Presets & Picker
                  Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      LiquidGlassChip(
                        label: 'Today',
                        isSelected: _isSameDay(_selectedDate, DateTime.now()),
                        onPressed: () => setState(() => _selectedDate = DateTime.now()),
                      ),
                      const SizedBox(width: 8),
                      LiquidGlassChip(
                        label: 'Yesterday',
                        isSelected: _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1))),
                        onPressed: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LiquidGlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          borderRadius: 14,
                          fillOpacity: 0.05,
                          onTap: () => _pickCustomDate(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.calendar, size: 14, color: isDark ? CupertinoColors.white : CupertinoColors.label),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM d').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? CupertinoColors.white : CupertinoColors.label,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isOverEnvelope) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CupertinoColors.systemRed.withValues(alpha: 0.35), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 14, color: CupertinoColors.systemRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Exceeds ${_selectedCategory.displayName} envelope target (₹${envBudget.toStringAsFixed(0)}) by ₹${(currentCatSpent + entersAmount - envBudget).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.systemRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),

                  // Submit Button
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(16),
                    onPressed: _submit,
                    child: Text(
                      _selectedType == ExpenseType.expense ? 'Save Expense' : 'Save Income',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickCustomDate(BuildContext context) async {
    DateTime temp = _selectedDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                CupertinoButton(
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() => _selectedDate = temp);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now().add(const Duration(days: 365)),
                minimumDate: DateTime(2020),
                onDateTimeChanged: (val) => temp = val,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
