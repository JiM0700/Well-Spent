enum ExpenseType { expense, income }

enum ExpenseKind { fixed, variable }

enum ExpenseCategory {
  food,
  transport,
  bills,
  shopping,
  healthcare,
  entertainment,
  invest,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.bills:
        return 'Bills & Utilities';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.healthcare:
        return 'Healthcare';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.invest:
        return 'Investments';
      case ExpenseCategory.other:
        return 'General / Other';
    }
  }

  String get iconName {
    switch (this) {
      case ExpenseCategory.food:
        return 'restaurant';
      case ExpenseCategory.transport:
        return 'directions_car';
      case ExpenseCategory.bills:
        return 'receipt';
      case ExpenseCategory.shopping:
        return 'shopping_bag';
      case ExpenseCategory.healthcare:
        return 'medical_services';
      case ExpenseCategory.entertainment:
        return 'movie';
      case ExpenseCategory.invest:
        return 'savings';
      case ExpenseCategory.other:
        return 'more_horiz';
    }
  }
}

extension ExpenseTypeExtension on ExpenseType {
  String get displayName {
    switch (this) {
      case ExpenseType.expense:
        return 'Expense';
      case ExpenseType.income:
        return 'Income';
    }
  }
}

extension ExpenseKindExtension on ExpenseKind {
  String get displayName {
    switch (this) {
      case ExpenseKind.fixed:
        return 'Fixed';
      case ExpenseKind.variable:
        return 'Variable';
    }
  }
}

class Expense {
  final int? id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final ExpenseType type;
  final ExpenseKind expenseKind;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.type = ExpenseType.expense,
    this.expenseKind = ExpenseKind.variable,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'note': note ?? '',
      'type': type.name,
      'expenseKind': expenseKind.name,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final expenseType = ExpenseType.values.firstWhere(
      (e) => e.name == (map['type'] as String? ?? ''),
      orElse: () => ExpenseType.expense,
    );
    final expenseKind = ExpenseKind.values.firstWhere(
      (e) => e.name == (map['expenseKind'] as String? ?? ''),
      orElse: () => ExpenseKind.variable,
    );

    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String? ?? ''),
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?)?.isNotEmpty == true ? map['note'] as String : null,
      type: expenseType,
      expenseKind: expenseKind,
    );
  }

  bool get isIncome => type == ExpenseType.income;
  bool get isExpense => type == ExpenseType.expense;

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    ExpenseType? type,
    ExpenseKind? expenseKind,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
      expenseKind: expenseKind ?? this.expenseKind,
    );
  }
}

class RecurringBill {
  final int id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final int dueDay; // 1 - 31
  final String frequency; // 'monthly' | 'yearly'
  final bool isActive;
  final DateTime? lastPaidDate;

  RecurringBill({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dueDay,
    this.frequency = 'monthly',
    this.isActive = true,
    this.lastPaidDate,
  });

  bool isPaidForCycle(DateTime cycleStart, DateTime cycleEnd) {
    if (lastPaidDate == null) return false;
    return (lastPaidDate!.isAfter(cycleStart.subtract(const Duration(seconds: 1))) ||
            lastPaidDate!.isAtSameMomentAs(cycleStart)) &&
        (lastPaidDate!.isBefore(cycleEnd.add(const Duration(seconds: 1))) ||
            lastPaidDate!.isAtSameMomentAs(cycleEnd));
  }

  int daysUntilDue(DateTime now) {
    final currentYear = now.year;
    final currentMonth = now.month;
    final maxDaysThisMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final day = dueDay.clamp(1, maxDaysThisMonth);
    DateTime dueDate = DateTime(currentYear, currentMonth, day);

    if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
      final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
      final nextYear = currentMonth == 12 ? currentYear + 1 : currentYear;
      final maxDaysNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      dueDate = DateTime(nextYear, nextMonth, dueDay.clamp(1, maxDaysNextMonth));
    }

    return dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  RecurringBill copyWith({
    int? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    int? dueDay,
    String? frequency,
    bool? isActive,
    DateTime? lastPaidDate,
  }) {
    return RecurringBill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDay: dueDay ?? this.dueDay,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      lastPaidDate: lastPaidDate ?? this.lastPaidDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'dueDay': dueDay,
      'frequency': frequency,
      'isActive': isActive ? 1 : 0,
      'lastPaidDate': lastPaidDate?.toIso8601String(),
    };
  }

  factory RecurringBill.fromMap(Map<String, dynamic> map) {
    return RecurringBill(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String? ?? ''),
        orElse: () => ExpenseCategory.bills,
      ),
      dueDay: (map['dueDay'] as num?)?.toInt() ?? 1,
      frequency: map['frequency'] as String? ?? 'monthly',
      isActive: map['isActive'] == 1 || map['isActive'] == true,
      lastPaidDate: map['lastPaidDate'] != null ? DateTime.tryParse(map['lastPaidDate'] as String) : null,
    );
  }
}
