import 'package:flutter/foundation.dart';

import 'package:phantom/models/check_in.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/models/practice.dart';
import 'package:phantom/repositories/check_in_repository.dart';
import 'package:phantom/utils/date_helpers.dart';

/// Tracking status for a goal's pace relative to its target.
enum TrackingStatus {
  /// User is meeting or exceeding the required pace.
  onTrack,

  /// User is behind but within 70% of the required pace.
  behind,

  /// User is significantly behind (below 70% of required pace).
  fallingOff,
}

/// Computed pace data for a single goal.
///
/// Contains the required vs actual sessions-per-week, the resulting
/// [TrackingStatus], overall progress percentage, and a human-readable label.
class PaceData {
  /// Sessions per week needed to meet the goal on time.
  final double requiredPace;

  /// Actual sessions per week (rolling 2-week average).
  final double actualPace;

  /// Current tracking status.
  final TrackingStatus status;

  /// Overall progress from 0.0 to 1.0.
  final double progressPercent;

  /// Human-readable status label: `'On track'`, `'Behind'`, or `'Falling off'`.
  final String progressLabel;

  const PaceData({
    required this.requiredPace,
    required this.actualPace,
    required this.status,
    required this.progressPercent,
    required this.progressLabel,
  });

  @override
  String toString() {
    return 'PaceData(required: $requiredPace/wk, actual: $actualPace/wk, '
        'status: $progressLabel, progress: ${(progressPercent * 100).toStringAsFixed(1)}%)';
  }
}

/// Pure-function pace calculator and statistics aggregator.
///
/// The [calculatePace] method is a pure function with no side effects,
/// making it fully unit-testable. [StatsProvider] wraps repository access
/// for aggregation queries used by dashboard and analytics views.
class StatsProvider extends ChangeNotifier {
  final CheckInRepository _checkInRepo;

  /// Creates a [StatsProvider] backed by the given [CheckInRepository].
  StatsProvider(this._checkInRepo);

  /// Returns all check-ins from the repository.
  List<CheckIn> get allCheckIns => _checkInRepo.getAll();

  // ─── Pure Pace Calculation ─────────────────────────────────────────

  /// Calculates pacing data for a [goal] given its [practices] and
  /// [checkIns].
  ///
  /// This is a **pure function** — it has no side effects and does not
  /// access any external state. Pass [now] to make it deterministic in
  /// tests.
  ///
  /// ### Algorithm
  /// 1. Compute weeks remaining until `goal.targetDate`.
  /// 2. Compute **requiredPace** (sessions/week needed):
  ///    - Milestone-based: remaining milestones / weeks remaining.
  ///    - Count-based: remaining count / weeks remaining.
  ///    - Fallback: sum of weekly targets across attached practices.
  /// 3. Compute **actualPace**: check-ins in the last 14 days / 2.
  /// 4. Determine [TrackingStatus] by comparing actual to required.
  /// 5. Compute overall **progressPercent** (0.0–1.0).
  static PaceData calculatePace({
    required Goal goal,
    required List<Practice> practices,
    required List<CheckIn> checkIns,
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

    // 1. Weeks remaining
    final daysRemaining = goal.targetDate.difference(currentDate).inDays;
    final weeksRemaining = (daysRemaining / 7).ceil().clamp(1, 9999);

    // 2. Required pace
    double requiredPace;
    if (goal.milestones.isNotEmpty) {
      final remaining =
          goal.milestones.where((m) => !m.isCompleted).length;
      requiredPace = remaining / weeksRemaining;
    } else if (goal.targetCount != null) {
      final done = checkIns.length;
      final remaining =
          (goal.targetCount! - done).clamp(0, goal.targetCount!);
      requiredPace = remaining / weeksRemaining;
    } else {
      requiredPace =
          practices.fold(0.0, (sum, p) => sum + p.weeklyTarget);
    }

    // 3. Actual pace — rolling 2-week window
    final twoWeeksAgo = currentDate.subtract(const Duration(days: 14));
    final recentCheckIns =
        checkIns.where((c) => c.timestamp.isAfter(twoWeeksAgo)).length;
    final actualPace = recentCheckIns / 2.0;

    // 4. Determine status
    TrackingStatus status;
    if (requiredPace <= 0) {
      status = TrackingStatus.onTrack;
    } else if (actualPace >= requiredPace) {
      status = TrackingStatus.onTrack;
    } else if (actualPace >= 0.7 * requiredPace) {
      status = TrackingStatus.behind;
    } else {
      status = TrackingStatus.fallingOff;
    }

    // 5. Progress percent
    double progressPercent;
    if (goal.milestones.isNotEmpty) {
      progressPercent =
          goal.completedMilestoneCount / goal.milestones.length;
    } else if (goal.targetCount != null && goal.targetCount! > 0) {
      progressPercent =
          (checkIns.length / goal.targetCount!).clamp(0.0, 1.0);
    } else {
      progressPercent =
          (goal.daysElapsed / goal.totalDays).clamp(0.0, 1.0);
    }

    return PaceData(
      requiredPace: requiredPace,
      actualPace: actualPace,
      status: status,
      progressPercent: progressPercent,
      progressLabel: status == TrackingStatus.onTrack
          ? 'On track'
          : status == TrackingStatus.behind
              ? 'Behind'
              : 'Falling off',
    );
  }

  // ─── Aggregation Methods ───────────────────────────────────────────

  /// Returns a map of domain → total check-in count.
  ///
  /// Each check-in is attributed to its goal's domain.
  Map<String, int> sessionsPerDomain(
    List<Goal> goals,
    List<CheckIn> checkIns,
  ) {
    final domainMap = <String, int>{};
    final goalDomains = {for (final g in goals) g.id: g.domain};

    for (final checkIn in checkIns) {
      final domain = goalDomains[checkIn.goalId] ?? 'Unknown';
      domainMap[domain] = (domainMap[domain] ?? 0) + 1;
    }

    return domainMap;
  }

  /// Returns a map of date (midnight) → check-in count for the last
  /// [days] days. Used for rendering a contribution heatmap.
  Map<DateTime, int> checkInsPerDay(
    List<CheckIn> checkIns, {
    int days = 90,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final dayMap = <DateTime, int>{};

    for (final checkIn in checkIns) {
      if (checkIn.timestamp.isBefore(cutoff)) continue;

      final day = DateTime(
        checkIn.timestamp.year,
        checkIn.timestamp.month,
        checkIn.timestamp.day,
      );
      dayMap[day] = (dayMap[day] ?? 0) + 1;
    }

    return dayMap;
  }

  /// Returns a map of week-start (Monday midnight) → check-in count
  /// for the last [weeks] weeks. Used for rendering a line chart.
  Map<DateTime, int> checkInsPerWeek(
    List<CheckIn> checkIns, {
    int weeks = 12,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: weeks * 7));
    final weekMap = <DateTime, int>{};

    for (final checkIn in checkIns) {
      if (checkIn.timestamp.isBefore(cutoff)) continue;

      final weekStart = PhantomDateHelpers.weekStart(checkIn.timestamp);
      weekMap[weekStart] = (weekMap[weekStart] ?? 0) + 1;
    }

    return weekMap;
  }

  /// Returns the total number of check-ins.
  int totalSessions(List<CheckIn> checkIns) => checkIns.length;

  /// Returns the total logged minutes across all check-ins that have
  /// a non-null [durationMinutes].
  int totalMinutes(List<CheckIn> checkIns) {
    return checkIns.fold(0, (sum, c) => sum + (c.durationMinutes ?? 0));
  }
}
