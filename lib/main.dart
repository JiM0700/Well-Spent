import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ios_shell_screen.dart';

ThemeData _buildAppleTheme({required Brightness brightness, required TargetPlatform platform}) {
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0A84FF);
  final primaryStrong = isDark ? const Color(0xFF5AC8FA) : const Color(0xFF2B7FFF);
  final background = isDark ? const Color(0xFF07111B) : const Color(0xFFF5F7FB);
  final surface = isDark ? const Color(0xFF121B27) : const Color(0xFFFFFFFF);
  final surfaceMuted = isDark ? const Color(0xFF182434) : const Color(0xFFF2F6FA);
  final textColor = isDark ? const Color(0xFFF5F9FF) : const Color(0xFF121A25);
  final mutedText = isDark ? const Color(0xFF9DB0C3) : const Color(0xFF6B7686);

  final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    secondary: primaryStrong,
    onSecondary: Colors.white,
    surface: surface,
    onSurface: textColor,
    background: background,
    onBackground: textColor,
    surfaceContainerHighest: surfaceMuted,
    outline: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06),
    outlineVariant: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
    tertiary: isDark ? const Color(0xFF4CC9F0) : const Color(0xFF64D2FF),
    onTertiary: Colors.white,
  );

  final baseTextTheme = brightness == Brightness.dark
      ? ThemeData.dark(useMaterial3: true).textTheme
      : ThemeData.light(useMaterial3: true).textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    platform: platform,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    textTheme: baseTextTheme.apply(bodyColor: textColor, displayColor: textColor),
    primaryTextTheme: baseTextTheme.apply(bodyColor: textColor, displayColor: textColor),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: baseTextTheme.titleLarge?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? const Color(0xFF162232).withOpacity(0.88) : const Color(0xFFFFFFFF).withOpacity(0.86),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? const Color(0xFF101723).withOpacity(0.96) : const Color(0xFFF8FAFF).withOpacity(0.96),
      modalBarrierColor: Colors.black.withOpacity(0.16),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 24),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1B2533) : const Color(0xFFF8FAFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 1.4)),
    ),
    iconTheme: IconThemeData(color: textColor),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primary, circularTrackColor: scheme.surfaceContainerHighest),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WellSpentApp());
}

class WellSpentApp extends StatelessWidget {
  const WellSpentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultPlatform = defaultTargetPlatform;
    final isApple = defaultPlatform == TargetPlatform.iOS || defaultPlatform == TargetPlatform.macOS;
    final targetPlatform = defaultPlatform == TargetPlatform.iOS
        ? TargetPlatform.iOS
        : defaultPlatform == TargetPlatform.macOS
            ? TargetPlatform.macOS
            : TargetPlatform.android;

    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider()..loadData(),
      child: MaterialApp(
        title: 'Well Spent',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _buildAppleTheme(brightness: Brightness.light, platform: isApple ? targetPlatform : TargetPlatform.android),
        darkTheme: _buildAppleTheme(brightness: Brightness.dark, platform: isApple ? targetPlatform : TargetPlatform.android),
        home: defaultPlatform == TargetPlatform.iOS
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
