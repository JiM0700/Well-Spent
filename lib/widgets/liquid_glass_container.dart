import 'dart:ui';
import 'package:flutter/cupertino.dart';

/// Reusable Apple-native Liquid Glass container.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;
  final Color? tintColor;
  final double fillOpacity;
  final bool hasBorder;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 18,
    this.blurAmount = 20,
    this.tintColor,
    this.fillOpacity = 0.08,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final baseFill = tintColor ?? (isDark ? CupertinoColors.white : CupertinoColors.black);

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseFill.withValues(alpha: isDark ? (fillOpacity * 1.5) : (fillOpacity * 0.8)),
                baseFill.withValues(alpha: isDark ? (fillOpacity * 0.7) : (fillOpacity * 0.3)),
              ],
            ),
            border: hasBorder
                ? Border.all(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.14)
                        : CupertinoColors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              if (isDark)
                BoxShadow(
                  color: CupertinoColors.white.withValues(alpha: 0.04),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: onTap != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onTap,
                child: content,
              )
            : content,
      );
    }

    if (onTap != null) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: content,
      );
    }

    return content;
  }
}
