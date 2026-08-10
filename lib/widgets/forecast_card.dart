import 'package:flutter/cupertino.dart';
import '../services/forecast_service.dart';

/// Clean Apple-native forecast card. No glass effects — just standard
/// Cupertino colours with green / red semantic indicators.
class ForecastCard extends StatelessWidget {
  final MonthlyForecast forecast;

  const ForecastCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final isWarning = forecast.projectedMonthEnd > forecast.monthlyBudget && forecast.monthlyBudget > 0;

    final primaryColor = CupertinoColors.systemGreen.resolveFrom(context);
    final dangerColor = CupertinoColors.systemRed.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final accentColor = isWarning ? dangerColor : primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                isWarning ? CupertinoIcons.arrow_up_right : CupertinoIcons.graph_square,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Projected Period End',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${forecast.daysRemaining} days left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Numbers row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Projected Total',
                      style: TextStyle(fontSize: 13, color: secondaryLabel)),
                  const SizedBox(height: 2),
                  Text(
                    '₹${forecast.projectedMonthEnd.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Daily Velocity',
                      style: TextStyle(fontSize: 13, color: secondaryLabel)),
                  const SizedBox(height: 2),
                  Text(
                    '₹${forecast.dailyVelocity.toStringAsFixed(2)} / day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Safe Burn Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Safe Daily Burn',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
                ),
                Text(
                  '₹${forecast.safeBurnRate.toStringAsFixed(2)} / day',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${forecast.daysUntilPayday} days left until payday · ₹${forecast.remainingIncome.toStringAsFixed(2)} available income',
            style: TextStyle(fontSize: 11, color: secondaryLabel),
          ),
          const SizedBox(height: 10),

          // Status message
          Text(
            forecast.statusMessage,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isWarning ? dangerColor : secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
