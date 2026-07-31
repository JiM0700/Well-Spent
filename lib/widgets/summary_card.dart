import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;

/// A clean, Apple-native summary card. Uses standard Cupertino colours and
/// grouped-background styling rather than custom glass effects.
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
    final tertiaryLabel = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$periodLabel Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: secondaryLabel,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: onEditBudget,
                child: Icon(CupertinoIcons.pencil, size: 18, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Big number
          Text(
            '₹${periodTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.41,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of ₹${periodBudget.toStringAsFixed(0)} budget',
            style: TextStyle(fontSize: 15, color: secondaryLabel),
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: usagePct,
                backgroundColor: tertiaryLabel.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? dangerColor : primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Metrics row
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: "Today's Spent",
                  value: '₹${todayTotal.toStringAsFixed(2)}',
                  icon: CupertinoIcons.calendar_today,
                ),
              ),
              Container(height: 36, width: 0.5, color: tertiaryLabel),
              Expanded(
                child: _MetricTile(
                  label: 'Remaining',
                  value: '₹${remainingBudget.toStringAsFixed(2)}',
                  icon: remainingBudget >= 0
                      ? CupertinoIcons.checkmark_seal
                      : CupertinoIcons.exclamationmark_triangle,
                  valueColor: remainingBudget < 0 ? dangerColor : null,
                ),
              ),
            ],
          ),

          // Summary section
          if (summaryEnabled) ...[
            const SizedBox(height: 16),
            Container(height: 0.5, color: tertiaryLabel.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              '$summaryWindowLabel Summary',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(summaryRangeLabel, style: TextStyle(fontSize: 13, color: secondaryLabel)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top category',
                          style: TextStyle(fontSize: 11, color: secondaryLabel)),
                      const SizedBox(height: 2),
                      Text(summaryTopCategoryLabel,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: labelColor)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Change vs previous',
                          style: TextStyle(fontSize: 11, color: secondaryLabel)),
                      const SizedBox(height: 2),
                      Text(summaryDifferenceLabel,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: labelColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: secondaryLabel)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? labelColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
