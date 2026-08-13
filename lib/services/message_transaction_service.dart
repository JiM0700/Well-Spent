import 'dart:async';

import 'package:flutter/services.dart';

/// Transactions discovered by Siri, Shortcuts, Share, or Messages.
class PendingTransaction {
  final String title;
  final double amount;
  final String? category;
  final DateTime date;
  final String? note;
  final String source;

  const PendingTransaction({
    required this.title,
    required this.amount,
    this.category,
    required this.date,
    this.note,
    required this.source,
  });

  factory PendingTransaction.fromMap(Map<dynamic, dynamic> map) {
    final rawDate = map['date']?.toString();
    return PendingTransaction(
      title: map['title']?.toString().trim().isNotEmpty == true ? map['title'].toString() : 'Imported transaction',
      amount: (map['amount'] as num?)?.toDouble() ?? double.tryParse('${map['amount']}') ?? 0,
      category: map['category']?.toString(),
      date: DateTime.tryParse(rawDate ?? '') ?? DateTime.now(),
      note: map['note']?.toString(),
      source: map['source']?.toString() ?? 'Messages',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'source': source,
      };
}

class MessageTransactionService {
  static const _channel = MethodChannel('well_spent/messages');
  static final MessageTransactionService instance = MessageTransactionService._();
  MessageTransactionService._();

  final _controller = StreamController<List<PendingTransaction>>.broadcast();
  Stream<List<PendingTransaction>> get transactions => _controller.stream;

  Future<List<PendingTransaction>> fetchPending() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('fetchPending');
      final items = (result ?? const []).whereType<Map>().map(PendingTransaction.fromMap).where((e) => e.amount > 0).toList();
      _controller.add(items);
      return items;
    } on MissingPluginException {
      return const [];
    }
  }

  Future<void> remove(PendingTransaction transaction) async {
    try { await _channel.invokeMethod('removePending', transaction.toMap()); } on MissingPluginException { }
  }

  void dispose() => _controller.close();
}
