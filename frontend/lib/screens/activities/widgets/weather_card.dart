import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/weather.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.isLoading,
    required this.weatherData,
  });

  final bool isLoading;
  final WeatherData? weatherData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        0,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          side: BorderSide(
            color: SyntrakColors.divider,
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SyntrakRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SyntrakColors.primary.withOpacity(0.1),
                SyntrakColors.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(SyntrakSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Highlights",
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.md),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(SyntrakSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (weatherData != null)
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weatherData!.condition.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(width: SyntrakSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${weatherData!.temperature.toStringAsFixed(1)}°C',
                                  style:
                                      SyntrakTypography.displaySmall.copyWith(
                                    color: SyntrakColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: SyntrakSpacing.xs),
                                Text(
                                  weatherData!.condition.description,
                                  style: SyntrakTypography.bodyMedium.copyWith(
                                    color: SyntrakColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (weatherData!.weeklyForecast.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...weatherData!.weeklyForecast.take(3).map((
                                forecast,
                              ) {
                                final dayName =
                                    DateFormat('E').format(forecast.date);
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: SyntrakSpacing.xs,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        dayName,
                                        style: SyntrakTypography.labelSmall
                                            .copyWith(
                                          color: SyntrakColors.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(width: SyntrakSpacing.xs),
                                      Text(
                                        '${forecast.maxTemp.toStringAsFixed(0)}°',
                                        style: SyntrakTypography.labelSmall
                                            .copyWith(
                                          color: SyntrakColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(SyntrakSpacing.md),
                    child: Text(
                      'Weather data unavailable',
                      style: SyntrakTypography.bodyMedium.copyWith(
                        color: SyntrakColors.textTertiary,
                      ),
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
