import 'package:flutter/foundation.dart';

import 'package:phantom/models/goal.dart';
import 'package:phantom/repositories/goal_repository.dart';
import 'package:phantom/repositories/practice_repository.dart';

/// Manages goal state and business logic.
///
/// Provides CRUD operations on goals, milestone toggling, and archival.
/// Depends on [GoalRepository] for persistence and [PracticeRepository]
/// for cascading deletes when a goal is removed.
class GoalProvider extends ChangeNotifier {
  final GoalRepository _goalRepo;
  final PracticeRepository _practiceRepo;

  List<Goal> _goals = [];

  /// Creates a [GoalProvider] and immediately loads all goals from storage.
  GoalProvider(this._goalRepo, this._practiceRepo) {
    loadGoals();
  }

  /// All goals, including archived.
  List<Goal> get goals => List.unmodifiable(_goals);

  /// Goals that are not archived.
  List<Goal> get activeGoals =>
      _goals.where((g) => !g.isArchived).toList();

  /// Goals that have been archived.
  List<Goal> get archivedGoals =>
      _goals.where((g) => g.isArchived).toList();

  /// All unique domain strings across every goal.
  List<String> get allDomains => _goalRepo.getAllDomains();

  /// Loads all goals from the repository into memory.
  void loadGoals() {
    _goals = _goalRepo.getAll();
    notifyListeners();
  }

  /// Persists a new [goal] and refreshes the in-memory list.
  Future<void> addGoal(Goal goal) async {
    await _goalRepo.save(goal);
    loadGoals();
  }

  /// Updates an existing [goal] and refreshes the in-memory list.
  Future<void> updateGoal(Goal goal) async {
    await _goalRepo.save(goal);
    loadGoals();
  }

  /// Deletes the goal with the given [id] and all practices attached to it.
  Future<void> deleteGoal(String id) async {
    // Cascade: delete all practices attached to this goal.
    final attachedPractices = _practiceRepo.getByGoalId(id);
    for (final practice in attachedPractices) {
      await _practiceRepo.delete(practice.id);
    }

    await _goalRepo.delete(id);
    loadGoals();
  }

  /// Archives the goal with the given [id].
  ///
  /// Archived goals are hidden from the active view but retained for
  /// historical reference.
  Future<void> archiveGoal(String id) async {
    final goal = _goalRepo.getById(id);
    if (goal == null) return;

    final archived = goal.copyWith(isArchived: true);
    await _goalRepo.save(archived);
    loadGoals();
  }

  /// Toggles the completion status of a milestone within a goal.
  ///
  /// Finds the milestone with [milestoneId] inside the goal identified
  /// by [goalId], flips its `isCompleted` flag, and persists the change.
  Future<void> toggleMilestone(String goalId, String milestoneId) async {
    final goal = _goalRepo.getById(goalId);
    if (goal == null) return;

    final updatedMilestones = goal.milestones.map((m) {
      if (m.id == milestoneId) {
        return m.copyWith(isCompleted: !m.isCompleted);
      }
      return m;
    }).toList();

    final updatedGoal = goal.copyWith(milestones: updatedMilestones);
    await _goalRepo.save(updatedGoal);
    loadGoals();
  }

  /// Returns the goal with the given [id], or `null` if not found.
  Goal? getById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
