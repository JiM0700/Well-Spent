import 'package:flutter/foundation.dart';

enum ExpenseCategory {
  food,
  transport,
  bills,
  shopping,
  healthcare,
  entertainment,
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
      case ExpenseCategory.other:
        return 'more_horiz';
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

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'note': note ?? '',
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
