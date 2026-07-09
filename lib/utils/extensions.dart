import 'package:phantom/utils/date_helpers.dart';

/// Extensions on [DateTime] for common date operations.
extension DateTimeExtensions on DateTime {
  /// Returns this date with time set to 00:00:00.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns this date with time set to 23:59:59.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Returns `true` if this date is today.
  bool get isToday => PhantomDateHelpers.isSameDay(this, DateTime.now());

  /// Returns `true` if this date falls within the current ISO week.
  bool get isThisWeek => PhantomDateHelpers.isSameWeek(this, DateTime.now());

  /// Formats this date as `'Jul 9, 2026'`.
  String get formatted => PhantomDateHelpers.formatDate(this);

  /// Formats this date as `'Jul 9'`.
  String get formattedShort => PhantomDateHelpers.formatDateShort(this);
}

/// Extensions on [String] for text formatting.
extension StringExtensions on String {
  /// Returns this string with its first character capitalized.
  ///
  /// Returns the original string if it is empty.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

/// Extensions on [Duration] for human-readable formatting.
extension DurationExtensions on Duration {
  /// Returns a human-readable duration string.
  ///
  /// Examples: `'2h 30m'`, `'45m'`, `'0m'`.
  String get humanReadable {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }
}
