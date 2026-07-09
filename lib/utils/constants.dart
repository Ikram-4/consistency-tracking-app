/// Effort levels for check-in entries.
///
/// Represents the intensity of a practice session:
/// - **Light** (1): Reading, watching, light review.
/// - **Moderate** (2): Active practice, problem solving.
/// - **Deep** (3): Focused, challenging work with high cognitive load.
class EffortLevel {
  EffortLevel._();

  static const int light = 1;
  static const int moderate = 2;
  static const int deep = 3;

  /// Returns a human-readable label for the given effort [level].
  static String label(int level) {
    switch (level) {
      case light:
        return 'Light';
      case moderate:
        return 'Moderate';
      case deep:
        return 'Deep';
      default:
        return 'Unknown';
    }
  }
}

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // ─── Hive Box Names ──────────────────────────────────────────────────

  /// Box name for storing [Goal] objects.
  static const String goalsBox = 'goals';

  /// Box name for storing [Practice] objects.
  static const String practicesBox = 'practices';

  /// Box name for storing [CheckIn] objects.
  static const String checkInsBox = 'check_ins';

  /// Box name for storing [WeeklyReview] objects.
  static const String weeklyReviewsBox = 'weekly_reviews';

  // ─── Domain Suggestions ──────────────────────────────────────────────

  /// Default autocomplete suggestions for goal domains.
  ///
  /// These are suggestions only — users can type any domain they want.
  static const List<String> defaultDomainSuggestions = [
    'Cybersecurity',
    'DSA',
    'System Design',
    'Web Development',
    'Networking',
    'Cloud',
    'DevOps',
    'Machine Learning',
    'Mobile Dev',
    'General',
  ];
}
