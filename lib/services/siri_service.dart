import 'package:flutter/services.dart';

class SiriService {
  static const _channel = MethodChannel('well_spent/siri');

  static Future<Map<String, dynamic>?> addTransaction({required double amount, required String title, String? category}) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('addTransaction', {
        'amount': amount, 'title': title, 'category': category ?? 'other',
      });
      return result?.map((key, value) => MapEntry(key.toString(), value));
    } on MissingPluginException {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getBudget() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBudget');
      return result?.map((key, value) => MapEntry(key.toString(), value));
    } on MissingPluginException { return null; }
  }

  static Future<Map<String, dynamic>?> getSpending({DateTime? since}) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSpending', {'since': since?.toIso8601String()});
      return result?.map((key, value) => MapEntry(key.toString(), value));
    } on MissingPluginException { return null; }
  }
}
