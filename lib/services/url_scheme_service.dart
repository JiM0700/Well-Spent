import 'dart:async';
import 'package:flutter/services.dart';

class UrlTransaction {
  final double amount;
  final String title;
  final String? category;
  const UrlTransaction({required this.amount, required this.title, this.category});
}

class UrlSchemeService {
  static const _channel = MethodChannel('well_spent/url_scheme');
  static final UrlSchemeService instance = UrlSchemeService._();
  UrlSchemeService._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'transaction') {
        final transaction = _parse(Map<dynamic, dynamic>.from(call.arguments as Map));
        if (transaction != null) _controller.add(transaction);
      }
    });
  }
  final _controller = StreamController<UrlTransaction>.broadcast();
  Stream<UrlTransaction> get transactions => _controller.stream;

  Future<void> start() async { try { await _channel.invokeMethod('getInitialURL'); } on MissingPluginException { } }

  UrlTransaction? _parse(Map<dynamic, dynamic> args) {
    final amount = double.tryParse('${args['amount']}');
    final title = '${args['title'] ?? ''}'.trim();
    if (amount == null || amount <= 0 || title.isEmpty) return null;
    return UrlTransaction(amount: amount, title: title, category: args['category']?.toString());
  }
}
