import '../models/check_in.dart';

/// Calculates the current check-in streak (consecutive days) for a practice.
///
/// Returns 0 if there are no logs for the practice, or if the user has not logged
/// a check-in either today or yesterday.
int calculateStreak(String practiceId, List<CheckIn> checkIns, DateTime today) {
  final practiceCheckIns = checkIns.where((c) => c.practiceId == practiceId).toList();
  if (practiceCheckIns.isEmpty) return 0;

  final todayDate = DateTime(today.year, today.month, today.day);
  final yesterdayDate = todayDate.subtract(const Duration(days: 1));

  final loggedToday = practiceCheckIns.any((c) =>
      DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day) == todayDate);
  final loggedYesterday = practiceCheckIns.any((c) =>
      DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day) == yesterdayDate);

  if (!loggedToday && !loggedYesterday) {
    return 0; // Broken streak
  }

  int streak = loggedToday ? 1 : 0;
  DateTime checkDate = yesterdayDate;

  // Count backwards day by day until a gap is found
  while (true) {
    final loggedOnDay = practiceCheckIns.any((c) =>
        DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day) == checkDate);
    if (loggedOnDay) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
}
