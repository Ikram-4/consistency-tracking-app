import 'package:hive_flutter/hive_flutter.dart';

import 'package:phantom/models/practice.dart';

/// Repository for persisting and retrieving [Practice] objects via Hive.
///
/// This is the only layer that directly interacts with Hive APIs for practices.
class PracticeRepository {
  static const boxName = 'practices';

  final Box _box;

  PracticeRepository(this._box);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Returns all practices in the box.
  List<Practice> getAll() {
    return _box.values
        .map((value) => Practice.fromMap(_castMap(value)))
        .toList();
  }

  /// Returns the practice with the given [id], or `null` if not found.
  Practice? getById(String id) {
    final value = _box.get(id);
    if (value == null) return null;
    return Practice.fromMap(_castMap(value));
  }

  /// Persists a practice. Overwrites any existing practice with the same id.
  Future<void> save(Practice practice) async {
    await _box.put(practice.id, practice.toMap());
  }

  /// Deletes the practice with the given [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all practices linked to the given [goalId].
  List<Practice> getByGoalId(String goalId) {
    return getAll().where((p) => p.goalId == goalId).toList();
  }

  /// Returns all active practices.
  List<Practice> getActive() {
    return getAll().where((p) => p.isActive).toList();
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
