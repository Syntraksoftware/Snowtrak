import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';

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
        return SyntrakColors.alpine;
      case ActivityType.crossCountry:
        return SyntrakColors.crossCountry;
      case ActivityType.freestyle:
        return SyntrakColors.freestyle;
      case ActivityType.backcountry:
        return SyntrakColors.backcountry;
      case ActivityType.snowboard:
        return SyntrakColors.snowboard;
      case ActivityType.other:
        return SyntrakColors.textSecondary;
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

