import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';

/// Helper functions for activity types with skiing-specific icons and colors
class ActivityHelpers {
  static IconData getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.alpine:
        return Icons.downhill_skiing;
      case ActivityType.crossCountry:
        return Icons.nordic_walking;
      case ActivityType.freestyle:
        return Icons.sports_gymnastics;
      case ActivityType.backcountry:
        return Icons.terrain;
      case ActivityType.snowboard:
        return Icons.snowboarding;
      case ActivityType.other:
        return Icons.snowshoeing;
    }
  }
  
  static Color getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.alpine:
        return SnowtrakColors.alpine;
      case ActivityType.crossCountry:
        return SnowtrakColors.crossCountry;
      case ActivityType.freestyle:
        return SnowtrakColors.freestyle;
      case ActivityType.backcountry:
        return SnowtrakColors.backcountry;
      case ActivityType.snowboard:
        return SnowtrakColors.snowboard;
      case ActivityType.other:
        return SnowtrakColors.textSecondary;
    }
  }
  
  static String getActivityDescription(ActivityType type) {
    switch (type) {
      case ActivityType.alpine:
        return 'Downhill skiing on groomed slopes';
      case ActivityType.crossCountry:
        return 'Cross-country skiing on trails';
      case ActivityType.freestyle:
        return 'Freestyle skiing and tricks';
      case ActivityType.backcountry:
        return 'Backcountry and off-piste skiing';
      case ActivityType.snowboard:
        return 'Snowboarding';
      case ActivityType.other:
        return 'Other winter activities';
    }
  }
}

