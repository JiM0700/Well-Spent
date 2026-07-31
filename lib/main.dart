import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ios_shell_screen.dart';

/// Apple-native green accent — calming finance colour.
const Color _kAccentGreen = CupertinoColors.systemGreen;
const Color _kAccentGreenDark = Color(0xFF30D158);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WellSpentApp());
}

class WellSpentApp extends StatelessWidget {
  const WellSpentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isApple = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider()..loadData(),
      child: isApple ? _buildCupertinoApp(platform) : _buildMaterialApp(),
    );
  }

  Widget _buildCupertinoApp(TargetPlatform platform) {
    return CupertinoApp(
      title: 'Well Spent',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        primaryColor: _kAccentGreen,
        brightness: null, // follow system
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        barBackgroundColor: CupertinoColors.systemBackground,
        textTheme: CupertinoTextThemeData(
          navLargeTitleTextStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 34,
            letterSpacing: 0.41,
            color: CupertinoColors.label,
          ),
          navTitleTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.41,
            color: CupertinoColors.label,
          ),
        ),
      ),
      home: platform == TargetPlatform.iOS
          ? const IosShellScreen()
          : const DashboardScreen(),
      routes: {
        '/analytics': (context) => const AnalyticsScreen(),
      },
    );
  }

  Widget _buildMaterialApp() {
    return MaterialApp(
      title: 'Well Spent',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildMaterialTheme(Brightness.light),
      darkTheme: _buildMaterialTheme(Brightness.dark),
      home: const DashboardScreen(),
      routes: {
        '/analytics': (context) => const AnalyticsScreen(),
      },
    );
  }

  ThemeData _buildMaterialTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = isDark ? _kAccentGreenDark : _kAccentGreen;
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
      ),
    );
  }
}
