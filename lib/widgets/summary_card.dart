import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final remainingBudget = periodBudget - periodTotal;
    final usagePct = periodBudget > 0 ? (periodTotal / periodBudget).clamp(0.0, 1.0) : 0.0;
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$periodLabel Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEditBudget,
              tooltip: 'Set Budget',
            ),
          ],
        ),
        const SizedBox(height: 8),

        Text(
          '₹${periodTotal.toStringAsFixed(2)}',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          'Spent this period of ₹${periodBudget.toStringAsFixed(0)} budget',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: usagePct,
            minHeight: 10,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              usagePct > 0.9 ? Colors.redAccent : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: "Today's Spent",
                value: '₹${todayTotal.toStringAsFixed(2)}',
                icon: Icons.today,
              ),
            ),
            Container(height: 30, width: 1, color: theme.colorScheme.outline.withOpacity(0.3)),
            Expanded(
              child: _MetricTile(
                label: "Remaining",
                value: '₹${remainingBudget.toStringAsFixed(2)}',
                icon: remainingBudget >= 0 ? Icons.savings_outlined : Icons.warning_amber_rounded,
                valueColor: remainingBudget < 0 ? Colors.redAccent : null,
              ),
            ),
          ],
        ),
        if (summaryEnabled) ...[
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            '$summaryWindowLabel Summary',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(summaryRangeLabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top category', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(summaryTopCategoryLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Change vs previous', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(summaryDifferenceLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (!isMac) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: theme.colorScheme.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: content,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface.withOpacity(0.75),
                theme.colorScheme.surface.withOpacity(0.45),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: theme.colorScheme.surface.withOpacity(0.58), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: content,
        ),
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
