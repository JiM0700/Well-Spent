import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final double currentMonthTotal;
  final double todayTotal;
  final double monthlyBudget;
  final VoidCallback onEditBudget;

  const SummaryCard({
    super.key,
    required this.currentMonthTotal,
    required this.todayTotal,
    required this.monthlyBudget,
    required this.onEditBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingBudget = monthlyBudget - currentMonthTotal;
    final usagePct = monthlyBudget > 0 ? (currentMonthTotal / monthlyBudget).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEditBudget,
                  tooltip: 'Set Monthly Budget',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Big Total Spent Number
            Text(
              '\$${currentMonthTotal.toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.extrabold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'Spent this month of \$${monthlyBudget.toStringAsFixed(0)} budget',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Budget Progress Bar
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

            // Today & Remaining metrics
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: "Today's Spent",
                    value: '\$${todayTotal.toStringAsFixed(2)}',
                    icon: Icons.today,
                  ),
                ),
                Container(height: 30, width: 1, color: theme.colorScheme.outline.withOpacity(0.3)),
                Expanded(
                  child: _MetricTile(
                    label: "Remaining",
                    value: '\$${remainingBudget.toStringAsFixed(2)}',
                    icon: remainingBudget >= 0 ? Icons.savings_outlined : Icons.warning_amber_rounded,
                    valueColor: remainingBudget < 0 ? Colors.redAccent : null,
                  ),
                ),
              ],
            ),
          ],
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
