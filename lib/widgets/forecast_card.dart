import 'package:flutter/cupertino.dart';
import '../services/forecast_service.dart';
import 'liquid_glass_container.dart';

/// Apple-native Liquid Glass Forecast Card (iOS / macOS 26 style).
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
    final accentColor = isWarning ? dangerColor : primaryColor;

    return LiquidGlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      fillOpacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWarning ? CupertinoIcons.arrow_up_right : CupertinoIcons.chart_bar_alt_fill,
                  color: accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Period Forecast',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 18),

          // Numbers row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROJECTED TOTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${forecast.projectedMonthEnd.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'DAILY VELOCITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${forecast.dailyVelocity.toStringAsFixed(0)} / day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Safe Burn Indicator Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (forecast.safeBurnRate > 0 ? primaryColor : dangerColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (forecast.safeBurnRate > 0 ? primaryColor : dangerColor).withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  forecast.safeBurnRate > 0 ? CupertinoIcons.shield_lefthalf_fill : CupertinoIcons.exclamationmark_triangle_fill,
                  size: 16,
                  color: forecast.safeBurnRate > 0 ? primaryColor : dangerColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    forecast.safeBurnRate > 0
                        ? 'Safe daily burn: ₹${forecast.safeBurnRate.toStringAsFixed(0)}/day to stay on budget'
                        : 'Budget exceeded. Reduce daily spend to recover.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
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
