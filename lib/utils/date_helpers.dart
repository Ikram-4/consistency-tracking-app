import 'package:intl/intl.dart';

/// Date utility methods for the Phantom app.
///
/// Named [PhantomDateHelpers] to avoid conflicting with Flutter's
/// built-in [DateUtils] class.
class PhantomDateHelpers {
  PhantomDateHelpers._();

  /// Returns Monday 00:00:00 of the week containing [date].
  static DateTime weekStart(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Returns Sunday 23:59:59 of the week containing [date].
  static DateTime weekEnd(DateTime date) {
    final daysUntilSunday = DateTime.sunday - date.weekday;
    final sunday = date.add(Duration(days: daysUntilSunday));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
  }

  /// Returns `true` if [a] and [b] fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns `true` if [a] and [b] fall within the same ISO week
  /// (Monday–Sunday).
  static bool isSameWeek(DateTime a, DateTime b) {
    final startA = weekStart(a);
    final startB = weekStart(b);
    return startA.year == startB.year &&
        startA.month == startB.month &&
        startA.day == startB.day;
  }

  /// Returns the number of weeks between [start] and [end] (ceiling).
  ///
  /// Always returns at least 1 to avoid division-by-zero errors.
  static int weeksBetween(DateTime start, DateTime end) {
    final days = end.difference(start).inDays.abs();
    return (days / 7).ceil().clamp(1, 9999);
  }

  /// Returns a human-readable relative date string.
  ///
  /// Examples: `'Today'`, `'Yesterday'`, `'3 days ago'`, `'Jul 5'`.
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference > 1 && difference <= 7) return '$difference days ago';
    return formatDateShort(date);
  }

  /// Formats [date] as `'Jul 9, 2026'`.
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  /// Formats [date] as `'Jul 9'`.
  static String formatDateShort(DateTime date) {
    return DateFormat.MMMd().format(date);
  }

  /// Formats [date] as `'2:30 PM'`.
  static String formatTime(DateTime date) {
    return DateFormat.jm().format(date);
  }

  /// Returns a list of [DateTime] objects, one per day, from [start] to
  /// [end] inclusive. Each DateTime has time zeroed out.
  static List<DateTime> daysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  /// Returns today's date with time zeroed out (midnight).
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns `true` if [date] falls on a Sunday.
  ///
  /// Used to trigger weekly review prompts.
  static bool isSunday(DateTime date) {
    return date.weekday == DateTime.sunday;
  }
}
