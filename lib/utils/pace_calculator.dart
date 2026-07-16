import '../models/goal.dart';
import '../models/practice.dart';
import '../models/check_in.dart';
import '../providers/stats_provider.dart'; // Reuse TrackingStatus / PaceData types
import 'date_helpers.dart';
import 'streak_calculator.dart';

/// Practice status details for pacing calculations.
class PracticeStanding {
  final Practice practice;
  final bool isBehind;
  final int completedThisWeek;
  final int weeklyTarget;

  const PracticeStanding({
    required this.practice,
    required this.isBehind,
    required this.completedThisWeek,
    required this.weeklyTarget,
  });
}

/// Standing summary results for the dashboard and widget.
class StandingSummary {
  final int onTrackCount;
  final int totalGoals;
  final List<Practice> behindPractices;
  final String? topBehindPracticeName;

  const StandingSummary({
    required this.onTrackCount,
    required this.totalGoals,
    required this.behindPractices,
    required this.topBehindPracticeName,
  });
}

/// Helper that calculates all goal and practice pacing.
/// Shared by NotificationService, DashboardScreen, StatsProvider, and WidgetService.
class PaceCalculator {
  /// Computes the overall standings summary.
  static StandingSummary calculateStandings({
    required List<Goal> activeGoals,
    required List<Practice> activePractices,
    required List<CheckIn> checkIns,
    required DateTime now,
    Goal? Function(String)? getGoalById,
  }) {
    final List<Practice> behindPractices = [];
    final startOfWeek = PhantomDateHelpers.weekStart(now);
    final endOfWeek = PhantomDateHelpers.weekEnd(now);
    final daysRemaining = 8 - now.weekday;

    for (final practice in activePractices) {
      final thisWeeksCheckIns = checkIns.where((c) {
        if (c.practiceId != practice.id) return false;
        return !c.timestamp.isBefore(startOfWeek) && !c.timestamp.isAfter(endOfWeek);
      }).toList();
      
      final completedCount = thisWeeksCheckIns.length;
      final sessionsNeeded = practice.weeklyTarget - completedCount;

      if (sessionsNeeded <= 0) continue; // Met weekly target

      final hasCheckedInToday = checkIns.any((c) {
        if (c.practiceId != practice.id) return false;
        return c.timestamp.year == now.year &&
            c.timestamp.month == now.month &&
            c.timestamp.day == now.day;
      });

      // Calculate expected linear pace by today
      final expectedLinear = (practice.weeklyTarget / 7.0) * now.weekday;

      // Nudge if:
      // a) Mathematically mandatory: sessions needed >= days remaining
      // b) Under linear target pace AND has not practiced yet today
      final isMandatory = sessionsNeeded >= daysRemaining;
      final isBehindExpected = completedCount < expectedLinear;

      if ((isMandatory || isBehindExpected) && !hasCheckedInToday) {
        behindPractices.add(practice);
      }
    }

    // Sort behind practices by priority (same algorithm as original)
    if (behindPractices.isNotEmpty) {
      behindPractices.sort((a, b) {
        final streakA = calculateStreak(a.id, checkIns, now);
        final streakB = calculateStreak(b.id, checkIns, now);

        final hasCheckedInTodayA = checkIns.any((c) {
          if (c.practiceId != a.id) return false;
          return c.timestamp.year == now.year &&
              c.timestamp.month == now.month &&
              c.timestamp.day == now.day;
        });
        
        final hasCheckedInTodayB = checkIns.any((c) {
          if (c.practiceId != b.id) return false;
          return c.timestamp.year == now.year &&
              c.timestamp.month == now.month &&
              c.timestamp.day == now.day;
        });

        final atRiskA = streakA >= 3 && !hasCheckedInTodayA;
        final atRiskB = streakB >= 3 && !hasCheckedInTodayB;

        // Highest active streak at risk today comes first
        if (atRiskA != atRiskB) {
          return atRiskA ? -1 : 1;
        }
        if (atRiskA) {
          if (streakA != streakB) {
            return streakB.compareTo(streakA); // Descending streak length
          }
        }

        // Then by how far behind weekly target
        final completedA = checkIns.where((c) {
          if (c.practiceId != a.id) return false;
          return !c.timestamp.isBefore(startOfWeek) && !c.timestamp.isAfter(endOfWeek);
        }).length;
        
        final completedB = checkIns.where((c) {
          if (c.practiceId != b.id) return false;
          return !c.timestamp.isBefore(startOfWeek) && !c.timestamp.isAfter(endOfWeek);
        }).length;

        final diffA = a.weeklyTarget - completedA;
        final diffB = b.weeklyTarget - completedB;
        if (diffA != diffB) {
          return diffB.compareTo(diffA); // Descending distance
        }

        // Then by earliest goal targetDate
        if (getGoalById != null) {
          final goalA = getGoalById(a.goalId);
          final goalB = getGoalById(b.goalId);
          if (goalA != null && goalB != null) {
            return goalA.targetDate.compareTo(goalB.targetDate); // Earliest first
          }
        }

        return 0;
      });
    }

    // Calculate onTrackCount for active goals
    int onTrackGoals = 0;
    for (final goal in activeGoals) {
      final goalCheckIns = checkIns.where((c) => c.goalId == goal.id).toList();
      final goalPractices = activePractices.where((p) => p.goalId == goal.id).toList();
      final pace = StatsProvider.calculatePace(
        goal: goal,
        practices: goalPractices,
        checkIns: goalCheckIns,
        now: now,
      );
      if (pace.status == TrackingStatus.onTrack) {
        onTrackGoals++;
      }
    }

    final topBehindName = behindPractices.isNotEmpty ? behindPractices.first.title : null;

    return StandingSummary(
      onTrackCount: onTrackGoals,
      totalGoals: activeGoals.length,
      behindPractices: behindPractices,
      topBehindPracticeName: topBehindName,
    );
  }
}
