import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassChip extends StatelessWidget {
  const LiquidGlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? tint.withOpacity(isDark ? 0.24 : 0.16)
                    : (isDark ? const Color(0x1FFFFFFF) : const Color(0xEAF1F4F8)),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? tint.withOpacity(isDark ? 0.34 : 0.28)
                      : (isDark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.3)),
                  width: selected ? 1.2 : 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.08 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? tint : theme.colorScheme.onSurfaceVariant,
                  letterSpacing: -0.08,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
