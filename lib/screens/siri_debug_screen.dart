import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/siri_service.dart';

/// Debug screen for testing Siri functionality on macOS
class SiriDebugScreen extends StatefulWidget {
  const SiriDebugScreen({Key? key}) : super(key: key);

  @override
  State<SiriDebugScreen> createState() => _SiriDebugScreenState();
}

class _SiriDebugScreenState extends State<SiriDebugScreen> {
  String _output = 'Test output will appear here...';
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _output = '${DateTime.now().toIso8601String()}: $message\n$_output';
    });
    print('[Siri Debug] $message');
  }

  Future<void> _testAddTransaction() async {
    setState(() => _isLoading = true);
    _log('Testing: addTransaction(amount: 50, title: "Coffee", category: "food")');
    
    try {
      final result = await SiriService.addTransaction(
        amount: 50,
        title: 'Coffee',
        category: 'food',
      );
      
      if (result != null) {
        _log('✅ Success: ${result['message']}');
        _log('Response: $result');
      } else {
        _log('❌ Failed: Plugin not available');
      }
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetBudget() async {
    setState(() => _isLoading = true);
    _log('Testing: getBudget()');
    
    try {
      final result = await SiriService.getBudget();
      
      if (result != null) {
        _log('✅ Budget Retrieved:');
        _log('  Monthly Budget: ₹${result['monthlyBudget']}');
        _log('  Spent: ₹${result['spent']}');
        _log('  Remaining: ₹${result['remaining']}');
        _log('  Period: ${result['period']}');
      } else {
        _log('❌ Failed: Plugin not available');
      }
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetSpending() async {
    setState(() => _isLoading = true);
    _log('Testing: getSpending()');
    
    try {
      final result = await SiriService.getSpending();
      
      if (result != null) {
        _log('✅ Spending Retrieved:');
        _log('  Spent: ₹${result['spent']}');
        _log('  Period: ${result['period']}');
        _log('  Transactions: ${result['transactions']}');
      } else {
        _log('❌ Failed: Plugin not available');
      }
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siri Debug Testing'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Test Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testAddTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Transaction (₹50 Coffee)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testGetBudget,
                  icon: const Icon(Icons.wallet),
                  label: const Text('Get Budget'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testGetSpending,
                  icon: const Icon(Icons.show_chart),
                  label: const Text('Get Spending'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _output = ''),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Output'),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(height: 1),
          
          // Output Console
          Expanded(
            child: Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  _output,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
