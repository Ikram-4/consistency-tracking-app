import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../repositories/goal_repository.dart';
import '../repositories/practice_repository.dart';
import '../repositories/check_in_repository.dart';
import '../utils/pace_calculator.dart';

/// Service that coordinates writing data to shared app preferences
/// so the native Android home screen widget can display up-to-date stats.
class WidgetService {
  WidgetService._();

  /// The single instance of [WidgetService].
  static final WidgetService instance = WidgetService._();

  late final GoalRepository _goalRepo;
  late final PracticeRepository _practiceRepo;
  late final CheckInRepository _checkInRepo;
  bool _isInitialized = false;

  /// Initializes the service with the required repositories.
  void initialize({
    required GoalRepository goalRepo,
    required PracticeRepository practiceRepo,
    required CheckInRepository checkInRepo,
  }) {
    _goalRepo = goalRepo;
    _practiceRepo = practiceRepo;
    _checkInRepo = checkInRepo;
    _isInitialized = true;
  }

  /// Calculates current standings and refreshes the home screen widget.
  Future<void> updateWidget() async {
    if (!_isInitialized) return;

    try {
      final now = DateTime.now();
      final activeGoals = _goalRepo.getActive();
      final activePractices = _practiceRepo.getActive();
      final checkIns = _checkInRepo.getAll();

      // Call shared calculation logic
      final summary = PaceCalculator.calculateStandings(
        activeGoals: activeGoals,
        activePractices: activePractices,
        checkIns: checkIns,
        now: now,
        getGoalById: (id) => _goalRepo.getById(id),
      );

      // Determine last check-in relative time label
      String lastLogLabel = 'No logs yet';
      if (checkIns.isNotEmpty) {
        // Sort by timestamp desc to get the latest
        final sorted = List.from(checkIns)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final latest = sorted.first.timestamp;
        final difference = now.difference(latest);

        if (difference.inMinutes < 1) {
          lastLogLabel = 'Last log: Just now';
        } else if (difference.inMinutes < 60) {
          lastLogLabel = 'Last log: ${difference.inMinutes}m ago';
        } else if (difference.inHours < 24) {
          lastLogLabel = 'Last log: ${difference.inHours}h ago';
        } else {
          lastLogLabel = 'Last log: ${difference.inDays}d ago';
        }
      }

      // Save shared widget data keys
      await HomeWidget.saveWidgetData('standing', '${summary.onTrackCount} / ${summary.totalGoals} on track');
      await HomeWidget.saveWidgetData('behind_practice', summary.topBehindPracticeName ?? '');
      await HomeWidget.saveWidgetData('last_log', lastLogLabel);
      await HomeWidget.saveWidgetData('has_data', 'true');

      // Request AppWidgetProvider update
      await HomeWidget.updateWidget(
        name: 'PhantomWidgetProvider',
        androidName: 'PhantomWidgetProvider',
      );
      debugPrint('Home widget updated successfully: ${summary.onTrackCount}/${summary.totalGoals}');
    } catch (e) {
      debugPrint('Error updating home widget data: $e');
    }
  }
}
