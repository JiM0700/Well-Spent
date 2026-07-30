import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ios_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WellSpentApp());
}

class WellSpentApp extends StatelessWidget {
  const WellSpentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider()..loadData(),
      child: MaterialApp(
        title: 'Well Spent',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,

        // Light Theme
        theme: ThemeData(
          useMaterial3: true,
          platform: isIOS ? TargetPlatform.iOS : TargetPlatform.android,
          colorScheme: ColorScheme.fromSeed(
            seedColor: isIOS ? const Color(0xFF007AFF) : const Color(0xFF1E88E5),
            brightness: Brightness.light,
            surface: isIOS ? const Color(0xFFF2F2F7) : Colors.white,
          ),
          scaffoldBackgroundColor: isIOS ? const Color(0xFFF2F2F7) : Colors.white,
          appBarTheme: isIOS
              ? const AppBarTheme(
                  backgroundColor: Color(0xCCF2F2F7),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                )
              : const BottomSheetThemeData(),
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
          bottomSheetTheme: isIOS
              ? const BottomSheetThemeData(
                  backgroundColor: Color(0xFFF2F2F7),
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                )
              : null,
        ),

        // Dark Theme (Ultra Sleek)
        darkTheme: ThemeData(
          useMaterial3: true,
          platform: isIOS ? TargetPlatform.iOS : TargetPlatform.android,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF42A5F5),
            brightness: Brightness.dark,
            surface: const Color(0xFF121824),
            background: const Color(0xFF0B0E14),
          ),
          scaffoldBackgroundColor: const Color(0xFF0B0E14),
          cardTheme: CardThemeData(
            color: isIOS ? const Color(0x331F2937) : null,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
        ),

        home: defaultTargetPlatform == TargetPlatform.iOS
            ? const IosShellScreen()
            : const DashboardScreen(),
        routes: {
          '/analytics': (context) => const AnalyticsScreen(),
          '/ios': (context) => const IosShellScreen(),
        },
      ),
    );
  }
}
