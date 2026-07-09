import 'package:flutter/foundation.dart';

import 'package:phantom/models/practice.dart';
import 'package:phantom/repositories/practice_repository.dart';

/// Manages practice state and business logic.
///
/// Provides CRUD operations for practices and filtering by goal or
/// active status. Depends on [PracticeRepository] for persistence.
class PracticeProvider extends ChangeNotifier {
  final PracticeRepository _practiceRepo;

  List<Practice> _practices = [];

  /// Creates a [PracticeProvider] and immediately loads all practices.
  PracticeProvider(this._practiceRepo) {
    loadPractices();
  }

  /// All practices, including inactive.
  List<Practice> get practices => List.unmodifiable(_practices);

  /// Only active practices.
  List<Practice> get activePractices =>
      _practices.where((p) => p.isActive).toList();

  /// Returns practices attached to the goal with [goalId].
  List<Practice> getByGoalId(String goalId) {
    return _practices.where((p) => p.goalId == goalId).toList();
  }

  /// Loads all practices from the repository into memory.
  void loadPractices() {
    _practices = _practiceRepo.getAll();
    notifyListeners();
  }

  /// Persists a new [practice] and refreshes the in-memory list.
  Future<void> addPractice(Practice practice) async {
    await _practiceRepo.save(practice);
    loadPractices();
  }

  /// Updates an existing [practice] and refreshes the in-memory list.
  Future<void> updatePractice(Practice practice) async {
    await _practiceRepo.save(practice);
    loadPractices();
  }

  /// Deletes the practice with the given [id].
  Future<void> deletePractice(String id) async {
    await _practiceRepo.delete(id);
    loadPractices();
  }

  /// Marks the practice with [id] as inactive.
  ///
  /// Deactivated practices are no longer shown in active views but
  /// their check-in history is preserved.
  Future<void> deactivatePractice(String id) async {
    final practice = getById(id);
    if (practice == null) return;

    final deactivated = practice.copyWith(isActive: false);
    await _practiceRepo.save(deactivated);
    loadPractices();
  }

  /// Returns the practice with the given [id], or `null` if not found.
  Practice? getById(String id) {
    try {
      return _practices.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
