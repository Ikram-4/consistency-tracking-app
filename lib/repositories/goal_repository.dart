import 'package:hive_flutter/hive_flutter.dart';

import 'package:phantom/models/goal.dart';

/// Repository for persisting and retrieving [Goal] objects via Hive.
///
/// This is the only layer that directly interacts with Hive APIs for goals.
/// All data is stored as `Map<String, dynamic>` and deserialized on read.
class GoalRepository {
  static const boxName = 'goals';

  final Box _box;

  GoalRepository(this._box);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Returns all goals in the box.
  List<Goal> getAll() {
    return _box.values.map((value) => Goal.fromMap(_castMap(value))).toList();
  }

  /// Returns the goal with the given [id], or `null` if not found.
  Goal? getById(String id) {
    final value = _box.get(id);
    if (value == null) return null;
    return Goal.fromMap(_castMap(value));
  }

  /// Persists a goal. Overwrites any existing goal with the same id.
  Future<void> save(Goal goal) async {
    await _box.put(goal.id, goal.toMap());
  }

  /// Deletes the goal with the given [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all goals that are not archived.
  List<Goal> getActive() {
    return getAll().where((goal) => !goal.isArchived).toList();
  }

  /// Returns all archived goals.
  List<Goal> getArchived() {
    return getAll().where((goal) => goal.isArchived).toList();
  }

  /// Returns a deduplicated list of all domain strings across every goal.
  List<String> getAllDomains() {
    return getAll().map((goal) => goal.domain).toSet().toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Deep-casts a Hive value (which may be `Map<dynamic, dynamic>`) into a
  /// properly typed `Map<String, dynamic>`, including nested maps and lists.
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
