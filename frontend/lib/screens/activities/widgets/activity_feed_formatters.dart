import 'package:intl/intl.dart';

/// Formats an elevation value in metres with a thousands separator.
/// e.g. 12345.6 → '12,346 m'
String formatElevation(double metres) {
  return '${NumberFormat('#,###').format(metres.round())} m';
}

/// Formats a duration in minutes as a human-readable string.
/// e.g. 150 → '2h 30m', 45 → '45m'
String formatDurationMinutes(int minutes) => formatMovingTimeSeconds(minutes * 60);

String formatRelativeActivityTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) return 'Just now';
      return '${difference.inMinutes}m ago';
    }
    return '${difference.inHours}h ago';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()}w ago';
  }
  return DateFormat('MMM d').format(date);
}

String formatMovingTimeSeconds(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}
