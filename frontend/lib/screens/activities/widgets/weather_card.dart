import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/weather.dart';
import 'package:snowtrak/screens/activities/widgets/home_section_card.dart';
import 'package:snowtrak/screens/activities/widgets/home_section_spacing.dart';
import 'package:snowtrak/screens/activities/widgets/home_selectable_chip.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({
    super.key,
    required this.isLoading,
    required this.weatherData,
  });

  final bool isLoading;
  final WeatherData? weatherData;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  int _selectedDayIndex = 0;

  @override
  void didUpdateWidget(covariant WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherData != widget.weatherData) {
      _selectedDayIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSectionSpacing(
      child: HomeSectionCard(
        icon: Icons.wb_cloudy_outlined,
        title: "Today's conditions",
        subtitle: 'Tap a day for the forecast',
        iconColor: context.colors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (widget.weatherData == null) {
      return Text(
        'Enable location or pull to refresh.',
        style: SnowtrakTypography.bodySmall.copyWith(
          color: context.colors.textTertiary,
        ),
      );
    }

    final data = widget.weatherData!;
    final forecastDays = data.weeklyForecast.take(3).toList();
    final selectedIndex = _selectedDayIndex - 1;
    final selected = selectedIndex >= 0 && selectedIndex < forecastDays.length
        ? forecastDays[selectedIndex]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(data.condition.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: SnowtrakSpacing.sm),
            Text(
              '${data.temperature.toStringAsFixed(0)}°',
              style: SnowtrakTypography.displaySmall.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 28,
                height: 1,
              ),
            ),
            const SizedBox(width: SnowtrakSpacing.sm),
            Expanded(
              child: Text(
                '${data.condition.description} · ${data.windSpeed.toStringAsFixed(0)} km/h wind',
                style: SnowtrakTypography.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (forecastDays.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: SnowtrakSpacing.xs,
            runSpacing: SnowtrakSpacing.xs,
            children: [
              HomeSelectableChip(
                label: 'Now',
                dense: true,
                selected: _selectedDayIndex == 0,
                onTap: () => setState(() => _selectedDayIndex = 0),
              ),
              for (var i = 0; i < forecastDays.length; i++)
                HomeSelectableChip(
                  label:
                      '${DateFormat('E').format(forecastDays[i].date)} ${forecastDays[i].maxTemp.toStringAsFixed(0)}°',
                  dense: true,
                  selected: _selectedDayIndex == i + 1,
                  onTap: () => setState(() => _selectedDayIndex = i + 1),
                ),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: SnowtrakSpacing.xs),
            Text(
              'High ${selected.maxTemp.toStringAsFixed(0)}° · '
              'Low ${selected.minTemp.toStringAsFixed(0)}° · '
              'Avg ${selected.avgTemp.toStringAsFixed(0)}°',
              style: SnowtrakTypography.labelSmall.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
