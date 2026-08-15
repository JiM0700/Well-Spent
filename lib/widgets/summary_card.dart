import 'package:flutter/cupertino.dart';
import 'liquid_glass_container.dart';

/// Apple-native Liquid Glass Summary Card (iOS / macOS 26 style).
class SummaryCard extends StatelessWidget {
  final String periodLabel;
  final double periodTotal;
  final double todayTotal;
  final double periodBudget;
  final VoidCallback onEditBudget;
  final bool summaryEnabled;
  final String summaryWindowLabel;
  final String summaryRangeLabel;
  final String summaryDifferenceLabel;
  final String summaryTopCategoryLabel;

  const SummaryCard({
    super.key,
    required this.periodLabel,
    required this.periodTotal,
    required this.todayTotal,
    required this.periodBudget,
    required this.onEditBudget,
    this.summaryEnabled = false,
    this.summaryWindowLabel = '',
    this.summaryRangeLabel = '',
    this.summaryDifferenceLabel = '',
    this.summaryTopCategoryLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final remainingBudget = periodBudget - periodTotal;
    final usagePct = periodBudget > 0 ? (periodTotal / periodBudget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = usagePct > 0.9;

    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final dangerColor = CupertinoColors.systemRed.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    return LiquidGlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      fillOpacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$periodLabel Overview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: secondaryLabel,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: onEditBudget,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.pencil, size: 12, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Budget',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big number
          Text(
            '₹${periodTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of ₹${periodBudget.toStringAsFixed(0)} budget',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: secondaryLabel),
          ),
          const SizedBox(height: 18),

          // Glowing Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              width: double.infinity,
              color: CupertinoColors.systemFill.resolveFrom(context),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: usagePct.clamp(0.0, 1.0),
                child: Container(
                  color: isOverBudget ? dangerColor : primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Sub metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REMAINING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${remainingBudget.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: remainingBudget < 0 ? dangerColor : primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${todayTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Optional summary banner
          if (summaryEnabled && summaryWindowLabel.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info_circle, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$summaryWindowLabel: $summaryDifferenceLabel ($summaryTopCategoryLabel)',
                      style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
