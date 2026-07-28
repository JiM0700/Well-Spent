import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WellSpentApp());
}

class WellSpentApp extends StatelessWidget {
  const WellSpentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider()..loadData(),
      child: MaterialApp(
        title: 'Well Spent',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,

        // Light Theme
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.light,
          ),
          cardTheme: const CardTheme(
            elevation: 2,
            margin: EdgeInsets.zero,
          ),
        ),

        // Dark Theme (Ultra Sleek)
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF42A5F5),
            brightness: Brightness.dark,
            surface: const Color(0xFF121824),
            background: const Color(0xFF0B0E14),
          ),
          scaffoldBackgroundColor: const Color(0xFF0B0E14),
          cardTheme: const CardTheme(
            elevation: 3,
            margin: EdgeInsets.zero,
          ),
        ),

        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
        },
      ),
    );
  }
}
