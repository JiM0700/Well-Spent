import 'package:flutter/cupertino.dart';
import '../services/siri_service.dart';
import '../widgets/liquid_glass_container.dart';

/// Debug screen for testing Siri functionality on macOS
class SiriDebugScreen extends StatefulWidget {
  const SiriDebugScreen({super.key});

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
    debugPrint('[Siri Debug] $message');
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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Siri Debug Testing'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Test Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: _isLoading ? null : _testAddTransaction,
                    child: const Text('Add Transaction (₹50 Coffee)'),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    color: CupertinoColors.activeBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: _isLoading ? null : _testGetBudget,
                    child: const Text('Get Budget', style: TextStyle(color: CupertinoColors.white)),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    color: CupertinoColors.systemIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: _isLoading ? null : _testGetSpending,
                    child: const Text('Get Spending', style: TextStyle(color: CupertinoColors.white)),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => setState(() => _output = ''),
                    child: const Text('Clear Output'),
                  ),
                ],
              ),
            ),
            
            // Output Console in LiquidGlassContainer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: LiquidGlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  fillOpacity: 0.12,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Text(
                      _output,
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 12,
                        color: isDark ? CupertinoColors.systemGreen : CupertinoColors.darkBackgroundGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
