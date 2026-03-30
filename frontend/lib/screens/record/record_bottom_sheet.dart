import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/record/record_helpers.dart';
import 'package:syntrak/services/location_service.dart';

/// Bottom sheet: start recording or live metrics + stop.
class RecordBottomSheet extends StatelessWidget {
  const RecordBottomSheet({
    super.key,
    required this.isRecording,
    required this.selectedActivityType,
    required this.locationService,
    required this.routePoints,
    required this.onSelectType,
    required this.onStart,
    required this.onStop,
  });

  final bool isRecording;
  final ActivityType? selectedActivityType;
  final LocationService locationService;
  final List<LatLng> routePoints;
  final VoidCallback onSelectType;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SyntrakSpacing.lg),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(SyntrakRadius.xl),
          topRight: Radius.circular(SyntrakRadius.xl),
        ),
        boxShadow: SyntrakElevation.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isRecording)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    selectedActivityType == null ? onSelectType : onStart,
                icon: selectedActivityType == null
                    ? const Icon(Icons.add)
                    : Icon(ActivityHelpers.getActivityIcon(selectedActivityType!)),
                label: Text(
                  selectedActivityType == null
                      ? 'Select Activity Type'
                      : 'Start Recording',
                  style: SyntrakTypography.labelLarge,
                ),
              ),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric(
                      'Vertical',
                      '${locationService.calculateElevationGain().toStringAsFixed(0)} m',
                    ),
                    _metric(
                      'Distance',
                      '${(locationService.calculateDistance() / 1000).toStringAsFixed(2)} km',
                    ),
                    _metric(
                      'Speed',
                      formatSpeedFromRouteTail(routePoints),
                    ),
                  ],
                ),
                const SizedBox(height: SyntrakSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SyntrakColors.error,
                      foregroundColor: SyntrakColors.textOnPrimary,
                    ),
                    child: Text(
                      'Stop Recording',
                      style: SyntrakTypography.labelLarge,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SyntrakTypography.metricMedium.copyWith(
              color: SyntrakColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SyntrakSpacing.xs),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: SyntrakColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
