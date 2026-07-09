import 'package:hive_flutter/hive_flutter.dart';

import 'package:phantom/models/check_in.dart';

/// Repository for persisting and retrieving [CheckIn] objects via Hive.
///
/// This is the only layer that directly interacts with Hive APIs for check-ins.
/// Provides rich querying by practice, goal, date range, and free-text search.
class CheckInRepository {
  static const boxName = 'check_ins';

  final Box _box;

  CheckInRepository(this._box);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Returns all check-ins in the box.
  List<CheckIn> getAll() {
    return _box.values
        .map((value) => CheckIn.fromMap(_castMap(value)))
        .toList();
  }

  /// Returns the check-in with the given [id], or `null` if not found.
  CheckIn? getById(String id) {
    final value = _box.get(id);
    if (value == null) return null;
    return CheckIn.fromMap(_castMap(value));
  }

  /// Persists a check-in. Overwrites any existing check-in with the same id.
  Future<void> save(CheckIn checkIn) async {
    await _box.put(checkIn.id, checkIn.toMap());
  }

  /// Deletes the check-in with the given [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all check-ins for the given [practiceId].
  List<CheckIn> getByPracticeId(String practiceId) {
    return getAll().where((c) => c.practiceId == practiceId).toList();
  }

  /// Returns all check-ins for the given [goalId].
  List<CheckIn> getByGoalId(String goalId) {
    return getAll().where((c) => c.goalId == goalId).toList();
  }

  /// Returns all check-ins whose timestamp falls within [start, end] inclusive.
  List<CheckIn> getByDateRange(DateTime start, DateTime end) {
    return getAll().where((c) {
      return !c.timestamp.isBefore(start) && !c.timestamp.isAfter(end);
    }).toList();
  }

  /// Returns check-ins for a specific [practiceId] within a date range.
  List<CheckIn> getByPracticeIdAndDateRange(
    String practiceId,
    DateTime start,
    DateTime end,
  ) {
    return getAll().where((c) {
      return c.practiceId == practiceId &&
          !c.timestamp.isBefore(start) &&
          !c.timestamp.isAfter(end);
    }).toList();
  }

  /// Searches check-ins whose [note] field contains [query] (case-insensitive).
  List<CheckIn> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((c) => c.note.toLowerCase().contains(lowerQuery)).toList();
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
