import 'package:intl/intl.dart';

class DateFormatter {
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal(); // Convert to local timezone
    final difference = now.difference(localDate);

    // Within last minute
    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    // Within last hour
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    // Within last 24 hours
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    // Within last 7 days
    if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat('h:mm a').format(localDate)}';
      }
      return '${DateFormat('EEEE').format(localDate)} at ${DateFormat('h:mm a').format(localDate)}';
    }

    // More than 7 days
    return '${DateFormat('MMM d, y').format(localDate)} at ${DateFormat('h:mm a').format(localDate)} (${_getTimezoneName()})';
  }

  static String formatScheduledDate(DateTime date) {
    final localDate = date.toLocal();
    return '${DateFormat('MMM d, y').format(localDate)} at ${DateFormat('h:mm a').format(localDate)} (${_getTimezoneName()})';
  }

  // Helper method to get timezone name
  static String _getTimezoneName() {
    final now = DateTime.now();
    final timezoneName = now.timeZoneName;
    final offset = now.timeZoneOffset;
    final offsetHours = offset.inHours;
    final offsetMinutes = (offset.inMinutes % 60).abs();

    final sign = offset.isNegative ? '-' : '+';
    final timeString =
        '$sign${offsetHours.abs().toString().padLeft(2, '0')}:${offsetMinutes.toString().padLeft(2, '0')}';

    return '$timezoneName (GMT$timeString)';
  }

  // Add method for hover tooltip full datetime
  static String getFullDateTime(DateTime date) {
    final localDate = date.toLocal();
    return '${DateFormat('EEEE, MMMM d, y').format(localDate)}\n'
        '${DateFormat('h:mm:ss a').format(localDate)}\n'
        'Timezone: ${_getTimezoneName()}';
  }
}
