import 'package:flutter/foundation.dart';

import 'package:phantom/models/check_in.dart';
import 'package:phantom/repositories/check_in_repository.dart';
import 'package:phantom/utils/date_helpers.dart';
import 'package:phantom/services/notification_service.dart';

/// Manages check-in state and business logic.
///
/// Provides CRUD operations, querying by practice/goal/date, and
/// aggregation helpers for weekly counts and search.
class CheckInProvider extends ChangeNotifier {
  final CheckInRepository _checkInRepo;

  List<CheckIn> _checkIns = [];

  /// Creates a [CheckInProvider] and immediately loads all check-ins.
  CheckInProvider(this._checkInRepo) {
    loadCheckIns();
  }

  /// All check-ins, unmodifiable.
  List<CheckIn> get checkIns => List.unmodifiable(_checkIns);

  /// Loads all check-ins from the repository into memory.
  void loadCheckIns() {
    _checkIns = _checkInRepo.getAll();
    notifyListeners();
  }

  /// Persists a new [checkIn] and refreshes the in-memory list.
  Future<void> addCheckIn(CheckIn checkIn) async {
    await _checkInRepo.save(checkIn);
    loadCheckIns();
    await NotificationService.instance.reschedule();
  }

  /// Deletes the check-in with the given [id].
  Future<void> deleteCheckIn(String id) async {
    await _checkInRepo.delete(id);
    loadCheckIns();
    await NotificationService.instance.reschedule();
  }

  /// Returns check-ins for the practice with [practiceId].
  List<CheckIn> getByPracticeId(String practiceId) {
    return _checkIns.where((c) => c.practiceId == practiceId).toList();
  }

  /// Returns check-ins for the goal with [goalId].
  List<CheckIn> getByGoalId(String goalId) {
    return _checkIns.where((c) => c.goalId == goalId).toList();
  }

  /// Returns check-ins with timestamps between [start] and [end] inclusive.
  List<CheckIn> getByDateRange(DateTime start, DateTime end) {
    return _checkIns.where((c) {
      return !c.timestamp.isBefore(start) && !c.timestamp.isAfter(end);
    }).toList();
  }

  /// Searches check-in notes for [query] (case-insensitive).
  List<CheckIn> search(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _checkIns
        .where((c) => c.note.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Returns the number of check-ins for [practiceId] in the current
  /// ISO week (Monday–Sunday).
  int countForPracticeThisWeek(String practiceId) {
    final now = DateTime.now();
    final start = PhantomDateHelpers.weekStart(now);
    final end = PhantomDateHelpers.weekEnd(now);

    return _checkIns.where((c) {
      return c.practiceId == practiceId &&
          !c.timestamp.isBefore(start) &&
          !c.timestamp.isAfter(end);
    }).length;
  }

  /// Returns the total number of check-ins for [goalId].
  ///
  /// Used for computing progress against a goal's [targetCount].
  int totalCountForGoal(String goalId) {
    return _checkIns.where((c) => c.goalId == goalId).length;
  }
}
