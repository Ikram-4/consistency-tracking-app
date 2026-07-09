import 'package:hive_flutter/hive_flutter.dart';

import 'package:phantom/models/weekly_review.dart';

/// Repository for persisting and retrieving [WeeklyReview] objects via Hive.
///
/// This is the only layer that directly interacts with Hive APIs for weekly
/// reviews.
class WeeklyReviewRepository {
  static const boxName = 'weekly_reviews';

  final Box _box;

  WeeklyReviewRepository(this._box);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Returns all weekly reviews in the box.
  List<WeeklyReview> getAll() {
    return _box.values
        .map((value) => WeeklyReview.fromMap(_castMap(value)))
        .toList();
  }

  /// Returns the weekly review with the given [id], or `null` if not found.
  WeeklyReview? getById(String id) {
    final value = _box.get(id);
    if (value == null) return null;
    return WeeklyReview.fromMap(_castMap(value));
  }

  /// Persists a weekly review. Overwrites any existing review with the same id.
  Future<void> save(WeeklyReview review) async {
    await _box.put(review.id, review.toMap());
  }

  /// Deletes the weekly review with the given [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns the weekly review for the week starting on [weekStart], or `null`.
  ///
  /// Matches by comparing year, month, and day of [weekStartDate].
  WeeklyReview? getByWeekStart(DateTime weekStart) {
    final reviews = getAll();
    for (final review in reviews) {
      if (review.weekStartDate.year == weekStart.year &&
          review.weekStartDate.month == weekStart.month &&
          review.weekStartDate.day == weekStart.day) {
        return review;
      }
    }
    return null;
  }

  /// Returns the most recently created weekly review, or `null` if none exist.
  WeeklyReview? getLatest() {
    final reviews = getAll();
    if (reviews.isEmpty) return null;
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews.first;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Deep-casts a Hive value into a properly typed `Map<String, dynamic>`.
  Map<String, dynamic> _castMap(dynamic value) {
    final map = Map<String, dynamic>.from(value as Map);
    for (final key in map.keys) {
      if (map[key] is List) {
        map[key] = (map[key] as List).map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return e;
        }).toList();
      } else if (map[key] is Map) {
        map[key] = Map<String, dynamic>.from(map[key] as Map);
      }
    }
    return map;
  }
}
