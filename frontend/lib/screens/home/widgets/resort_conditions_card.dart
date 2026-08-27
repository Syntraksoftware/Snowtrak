import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/weather.dart';
import 'package:snowtrak/screens/home/home_stats.dart';
import 'package:snowtrak/ui/st/st.dart';

/// The first thing on Home: where you are, what it's doing there, and the one
/// action the product exists for. Built to `07 · Screens — Home` → `ResortCard`.
class ResortConditionsCard extends StatelessWidget {
  const ResortConditionsCard({
    super.key,
    required this.weather,
    required this.isLoading,
    required this.onStartSession,
    this.resortName,
  });

  final WeatherData? weather;
  final bool isLoading;
  final VoidCallback onStartSession;

  /// Null until there is a resort lookup; the card falls back to the device
  /// location wording.
  final String? resortName;

  @override
  Widget build(BuildContext context) {
    return StCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _place()),
                const SizedBox(width: SnowtrakSpacing.smd),
                _temperature(),
              ],
            ),
          ),
          const StHairline(),
          _conditionsStrip(),
          StInkButton(
            label: 'Start Session Here',
            onTap: onStartSession,
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: SnowtrakColors.textOnPrimary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward,
              size: 15,
              color: SnowtrakColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _place() {
    final condition = weather?.condition;
    final wind = weather == null
        ? null
        : '${(weather!.windSpeed * 0.621371).round()} mph wind';
    final subtitle = [
      if (condition != null) condition.description,
      if (wind != null) wind,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: SnowtrakColors.live,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              resortName == null ? "TODAY'S CONDITIONS" : 'NEARBY RESORT',
              style: SnowtrakTypography.eyebrow.copyWith(
                color: SnowtrakColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          resortName ?? 'Your location',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SnowtrakTypography.headlineMedium.copyWith(
            color: SnowtrakColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          isLoading
              ? 'Reading conditions…'
              : subtitle.isEmpty
                  ? 'Enable location or pull to refresh'
                  : subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SnowtrakTypography.bodyMedium.copyWith(
            color: SnowtrakColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _temperature() {
    final temp = weather?.temperature;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        StIcon(
          _weatherIcon(weather?.condition),
          size: 28,
          color: SnowtrakColors.textSecondary,
        ),
        const SizedBox(height: 3),
        Text(
          temp == null ? '—' : '${Imperial.fahrenheit(temp).round()}°F',
          style: SnowtrakTypography.metricLarge.copyWith(
            color: SnowtrakColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          temp == null
              ? 'No reading'
              : 'Feels like ${Imperial.fahrenheit(temp).round()}°F',
          style: SnowtrakTypography.labelMedium.copyWith(
            fontSize: 11,
            color: SnowtrakColors.textTertiary,
          ),
        ),
      ],
    );
  }

  static String _weatherIcon(WeatherCondition? condition) {
    switch (condition) {
      case WeatherCondition.snow:
        return StIcons.ski;
      case WeatherCondition.sunny:
        return StIcons.lightning;
      case null:
        return StIcons.pin;
      default:
        return StIcons.activity;
    }
  }

  // ponytail: snow depth / lifts / slopes have no feed yet — the tiles hold
  // their place with an em dash rather than showing invented numbers. Wire them
  // when map-backend exposes resort conditions.
  Widget _conditionsStrip() {
    const tiles = [
      ('Snow Depth', StIcons.ski),
      ('New Snow', StIcons.lightning),
      ('Lifts Open', StIcons.activity),
      ('Slopes Open', StIcons.pin),
    ];

    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              const Center(
                child: SizedBox(
                  width: 1,
                  height: 44,
                  child: ColoredBox(color: SnowtrakColors.border),
                ),
              ),
            Expanded(
              child: StStatTile(
                value: '—',
                label: tiles[i].$1,
                icon: tiles[i].$2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
