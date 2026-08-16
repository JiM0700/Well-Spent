import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// An Apple-native Cupertino chip with frosted Liquid Glass styling.
class LiquidGlassChip extends StatelessWidget {
  final String label;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color? activeColor;

  const LiquidGlassChip({
    super.key,
    required this.label,
    this.leading,
    required this.isSelected,
    required this.onPressed,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final primary = activeColor ?? CupertinoColors.systemGreen.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? primary.withValues(alpha: isDark ? 0.28 : 0.18)
                  : (isDark ? CupertinoColors.white.withValues(alpha: 0.06) : CupertinoColors.black.withValues(alpha: 0.04)),
              border: Border.all(
                color: isSelected
                    ? primary.withValues(alpha: 0.8)
                    : (isDark ? CupertinoColors.white.withValues(alpha: 0.12) : CupertinoColors.black.withValues(alpha: 0.08)),
                width: isSelected ? 1.4 : 0.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? CupertinoColors.white : primary)
                        : (isDark ? CupertinoColors.label : CupertinoColors.darkBackgroundGray),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
