import '../models/check_in.dart';
import '../models/habit_model.dart';
import '../models/goal.dart' show HabitProfile;
import '../models/projection_confidence.dart';

/// Derives [HabitState] and consistency metrics for a goal by replaying its
/// historical check-ins through [HabitModel].
///
/// ## Consistency model
///
/// Consistency is **per-goal and effort-weighted**: for each calendar day the
/// repository sums the [CheckIn.weight] values of all check-ins for that
/// specific goal. That total effort [E] is passed through
/// [HabitModel.effortToConsistency] (a diminishing-returns curve) before
/// being handed to [HabitModel.step]. This replaces the old integer-count
/// approach and means two short sessions (weight 0.5 each) are equivalent
/// to one normal session (weight 1.0).
///
/// ## Streak tracking
///
/// During replay, if a day's total effort E > 0 the [HabitState.streakDays]
/// counter is incremented; if E == 0 it resets to 0. This feeds into the
/// focus-growth multiplier via [HabitModel.streakMultiplier].
///
/// ## Habit Profiles
///
/// Tones the consistency formula parameters per goal based on its profile:
/// - `frequency`: lower effortScale (small weights saturate consistency quickly)
/// - `duration`: baseline default configuration
/// - `singleSession`: low effortScale (single check-in near 1.0 saturates to max)
/// - `intensity`: higher maxDailyConsistency ceiling (4.0)
///
/// This repository is purely computational — it reads from an injected list of
/// [CheckIn] objects and has no Hive dependency of its own, keeping it easily
/// testable.
class HabitRepository {
  final List<CheckIn> _checkIns;
  final HabitModel _model;
  final HabitProfile Function(String goalId)? _profileLookup;

  /// In-memory cache: goalId → last computed [HabitState].
  ///
  /// Stores the state as of the most recent replay so [currentState] can
  /// avoid replaying from day 0 when nothing has changed.
  final Map<String, HabitState> _cache = {};

  /// The latest check-in timestamp seen per goalId at the time the cache
  /// entry was written. Used to detect whether new check-ins have arrived.
  final Map<String, DateTime?> _cacheWatermark = {};

  /// Creates a [HabitRepository] backed by [checkIns].
  ///
  /// Pass a [HabitModel] to override default a/b parameters; defaults are used
  /// when omitted.
  ///
  /// Provide an optional [profileLookup] function to retrieve a goal's profile;
  /// if omitted or returning null, defaults to [HabitProfile.duration].
  HabitRepository({
    required List<CheckIn> checkIns,
    HabitModel model = const HabitModel(),
    HabitProfile Function(String goalId)? profileLookup,
  })  : _checkIns = checkIns,
        _model = model,
        _profileLookup = profileLookup;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Reconstructs the current [HabitState] for [goalId] by replaying all
  /// stored daily check-ins through [HabitModel.step], starting from
  /// [HabitState.initial].
  ///
  /// Each calendar day is processed once. The daily effort [E] is the sum of
  /// [CheckIn.weight] for all check-ins on that day for this goal; that value
  /// is converted to a consistency via [HabitModel.effortToConsistency] tuned
  /// by the goal's [HabitProfile].
  ///
  /// Results are **memoised**: if no new check-ins have arrived for [goalId]
  /// since the last call, the cached [HabitState] is returned without
  /// replaying from scratch.
  HabitState currentState(String goalId) {
    final goalCheckIns = _checkInsForGoal(goalId);
    if (goalCheckIns.isEmpty) return HabitState.initial();

    final latestTimestamp = goalCheckIns
        .map((c) => c.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // Cache hit: no new check-ins since last computation.
    if (_cache.containsKey(goalId) &&
        _cacheWatermark[goalId] == latestTimestamp) {
      return _cache[goalId]!;
    }

    final profile = _profileLookup?.call(goalId) ?? HabitProfile.duration;
    final config = HabitProfileConfig.byProfile[profile] ?? HabitProfileConfig.duration;

    // Full replay from the earliest check-in day through today.
    final effortByDay = _effortByDay(goalCheckIns);
    final firstDay = effortByDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    final lastDay = _today();

    var state = HabitState.initial();
    var cursor = firstDay;

    while (!cursor.isAfter(lastDay)) {
      final effort = effortByDay[cursor] ?? 0.0;
      final consistency = HabitModel.effortToConsistency(
        effort,
        maxDailyConsistency: config.maxDailyConsistency,
        effortScale: config.effortScale,
      );
      final hadEffort = effort > 0.0;
      state = _model.step(
        state,
        consistency,
        hadEffort: hadEffort,
        maxDailyConsistency: config.maxDailyConsistency,
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    // Update cache.
    _cache[goalId] = state;
    _cacheWatermark[goalId] = latestTimestamp;

    return state;
  }

  /// Returns the trailing [days]-day average **consistency** for [goalId].
  ///
  /// For each day in the window the total effort [E] (sum of weights) is
  /// converted to a consistency value via [HabitModel.effortToConsistency] tuned
  /// by the goal's [HabitProfile].
  double trailingConsistency(String goalId, {int days = 30}) {
    assert(days > 0);
    final today = _today();
    final windowStart = today.subtract(Duration(days: days - 1));
    final goalCheckIns = _checkInsForGoal(goalId);
    final effortByDay = _effortByDay(goalCheckIns);

    final profile = _profileLookup?.call(goalId) ?? HabitProfile.duration;
    final config = HabitProfileConfig.byProfile[profile] ?? HabitProfileConfig.duration;

    double total = 0.0;
    var cursor = windowStart;
    while (!cursor.isAfter(today)) {
      final effort = effortByDay[cursor] ?? 0.0;
      total += HabitModel.effortToConsistency(
        effort,
        maxDailyConsistency: config.maxDailyConsistency,
        effortScale: config.effortScale,
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    return total / days;
  }

  /// Returns a [ProjectionResult] containing the projected day index,
  /// combined confidence, and confidence label.
  ProjectionResult projectedCompletionDay(String goalId, double goal) {
    final goalCheckIns = _checkInsForGoal(goalId);
    if (goalCheckIns.isEmpty) {
      return const ProjectionResult(
        projectedDay: null,
        confidence: 0.0,
        label: 'Low',
      );
    }

    final state = currentState(goalId);
    final consistency = trailingConsistency(goalId);

    final profile = _profileLookup?.call(goalId) ?? HabitProfile.duration;
    final config = HabitProfileConfig.byProfile[profile] ?? HabitProfileConfig.duration;

    final projectedDay = _model.projectCompletionDay(
      current: state,
      goal: goal,
      assumedConsistency: consistency,
      maxDailyConsistency: config.maxDailyConsistency,
    );

    // Compute confidence scores
    final firstDay = _midnight(
      goalCheckIns.map((c) => c.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
    );
    final historyDays = _today().difference(firstDay).inDays + 1;
    final volume = ProjectionConfidence.volumeScore(historyDays);

    final dailyConsistencies = <double>[];
    final effortByDay = _effortByDay(goalCheckIns);
    var cursor = firstDay;
    final lastDay = _today();
    while (!cursor.isAfter(lastDay)) {
      final effort = effortByDay[cursor] ?? 0.0;
      final dailyConsistency = HabitModel.effortToConsistency(
        effort,
        maxDailyConsistency: config.maxDailyConsistency,
        effortScale: config.effortScale,
      );
      dailyConsistencies.add(dailyConsistency);
      cursor = cursor.add(const Duration(days: 1));
    }

    final variance = ProjectionConfidence.varianceScore(dailyConsistencies);
    final confidence = ProjectionConfidence.confidenceScore(volume, variance);
    final label = ProjectionConfidence.confidenceLabel(confidence);

    return ProjectionResult(
      projectedDay: projectedDay,
      confidence: confidence,
      label: label,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Filters check-ins to those belonging to [goalId].
  List<CheckIn> _checkInsForGoal(String goalId) =>
      _checkIns.where((c) => c.goalId == goalId).toList();

  /// Builds a map from midnight-normalised day → total effort (sum of weights)
  /// for the supplied [goalCheckIns].
  Map<DateTime, double> _effortByDay(List<CheckIn> goalCheckIns) {
    final result = <DateTime, double>{};
    for (final c in goalCheckIns) {
      final day = _midnight(c.timestamp);
      result[day] = (result[day] ?? 0.0) + c.weight;
    }
    return result;
  }

  /// Normalises [dt] to midnight (00:00:00.000) to allow Map key equality.
  DateTime _midnight(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns today at midnight.
  DateTime _today() => _midnight(DateTime.now());
}
