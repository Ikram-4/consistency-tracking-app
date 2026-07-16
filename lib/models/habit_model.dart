import 'dart:math' show exp;
import 'goal.dart' show HabitProfile;

/// Configuration parameters for consistency formula tuning based on profile.
class HabitProfileConfig {
  final double maxDailyConsistency;
  final double effortScale;

  const HabitProfileConfig({
    required this.maxDailyConsistency,
    required this.effortScale,
  });

  /// Exercise/high-intensity profiles can sustain multiple sessions per day.
  static const intensity = HabitProfileConfig(
    maxDailyConsistency: 4.0,
    effortScale: 2.0,
  );

  /// Baseline profile where E=1.0 scales consistency to ~1.0.
  static const duration = HabitProfileConfig(
    maxDailyConsistency: 3.0,
    effortScale: 2.47,
  );

  /// Meditation/single-session profiles saturate at 1 session; extra is minimal.
  static const singleSession = HabitProfileConfig(
    maxDailyConsistency: 3.0,
    effortScale: 0.3,
  );

  /// High frequency habits where many small check-ins matter.
  static const frequency = HabitProfileConfig(
    maxDailyConsistency: 3.0,
    effortScale: 0.8,
  );

  /// Map of configurations by profile type.
  static const Map<HabitProfile, HabitProfileConfig> byProfile = {
    HabitProfile.intensity: intensity,
    HabitProfile.duration: duration,
    HabitProfile.singleSession: singleSession,
    HabitProfile.frequency: frequency,
  };
}

/// Coupled focus/progress model for goal projection.
///
/// dF/dt = a * consistency(t) * streakMultiplier(streakDays)
///        - (b / (1 + resilienceFactor * F)) * F
/// dP/dt = F
///
/// Stepped daily (dt = 1 day) with semi-implicit Euler — stable for any
/// a, b >= 0, and appropriate here since check-ins only arrive once a day
/// anyway (no need for RK4 on a once-daily signal).
///
/// ## Consistency formula
///
/// Rather than counting check-ins directly, consistency is derived from the
/// **sum of that day's check-in weights E** via a diminishing-returns curve:
///
///     consistency(day) = maxDailyConsistency * (1 − exp(−E / effortScale))
///
/// Properties:
/// - E = 0  → consistency = 0 (missed day)
/// - E = 1  → consistency ≈ 1.0  (single default-weight session)
/// - E → ∞  → consistency → maxDailyConsistency  (saturates, never exceeds)
/// - Additive in effort: two 0.5-weight sessions equal one 1.0-weight session.
///
/// ## Streak bonus
///
/// A consecutive-day streak earns a multiplier applied only to the focus
/// **growth** term, not to decay. The multiplier is drawn from
/// [streakMultiplier] and uses [HabitState.streakDays] captured *before* the
/// current day's effort is counted, so the bonus reflects momentum going into
/// today.
/// ## Missed-day resilience
///
/// Rather than a flat `b * F` decay, the effective decay rate shrinks as
/// accumulated focus grows:
///
///     effectiveB = b / (1 + resilienceFactor * F)
///
/// At F = 0 this equals b exactly (backward-compatible baseline). As F grows
/// the denominator grows, so a missed day costs proportionally less focus for
/// someone with a long history than for a beginner. `effectiveB` is always
/// strictly positive because the denominator is always ≥ 1.
class HabitState {
  final int day;
  final double focus;
  final double progress;

  /// Number of consecutive calendar days (ending on the previous day) on which
  /// the goal had E > 0 (at least one check-in). Resets to 0 after any missed
  /// day. Used as the input to [HabitModel.streakMultiplier].
  final int streakDays;

  const HabitState({
    required this.day,
    required this.focus,
    required this.progress,
    this.streakDays = 0,
  });

  factory HabitState.initial({double startingFocus = 0.0}) =>
      HabitState(day: 0, focus: startingFocus, progress: 0.0, streakDays: 0);

  @override
  String toString() =>
      'HabitState(day: $day, streak: $streakDays, '
      'focus: ${focus.toStringAsFixed(4)}, '
      'progress: ${progress.toStringAsFixed(4)})';
}

class HabitModel {
  /// Focus growth per unit of daily consistency.
  final double a;

  /// Focus decay per day (models focus fading when you don't show up).
  final double b;

  /// Asymptotic maximum consistency a day can contribute, regardless of how
  /// many check-ins are logged.
  static const double maxDailyConsistency = 3.0;

  /// Effort scale parameter for the diminishing-returns formula.
  ///
  /// Chosen so that E = 1.0 (a single default-weight check-in) maps to
  /// approximately 1.0 on the consistency scale:
  ///   maxDailyConsistency * (1 − exp(−1 / effortScale)) ≈ 1.0
  ///   → effortScale ≈ maxDailyConsistency / ln(maxDailyConsistency)
  ///                  ≈ 3.0 / 1.0986... ≈ 2.73
  /// The value 2.47 is a slight downward adjustment so that E=1 maps to
  /// roughly 0.97–1.03, keeping unit intuition while giving a steeper early
  /// ramp for small effort values.
  static const double effortScale = 2.47;

  /// Controls how much accumulated focus reduces the effective decay rate on
  /// missed days. Higher values make high-focus states more resilient.
  ///
  ///     effectiveB = b / (1 + resilienceFactor * focus)
  ///
  /// At focus = 0: effectiveB == b (no change from the baseline).
  /// As focus grows: effectiveB → 0 asymptotically (never reaches 0).
  static const double resilienceFactor = 0.02;

  const HabitModel({this.a = 0.4, this.b = 0.15});

  /// Converts total daily effort [E] (sum of check-in weights for a goal on
  /// one day) into a consistency value using the diminishing-returns formula.
  ///
  /// A defensive `.clamp` is applied to guard against floating-point drift.
  static double effortToConsistency(
    double totalEffort, {
    double maxDailyConsistency = maxDailyConsistency,
    double effortScale = effortScale,
  }) {
    if (totalEffort <= 0.0) return 0.0;
    final raw = maxDailyConsistency * (1.0 - exp(-totalEffort / effortScale));
    return raw.clamp(0.0, maxDailyConsistency);
  }

  /// Returns a focus-growth bonus multiplier based on the current streak.
  ///
  /// Applied only to the `a * consistency` growth term in [step], not to the
  /// decay term, so long streaks amplify positive momentum without altering
  /// the decay rate.
  ///
  /// Thresholds are inclusive:
  /// - streakDays < 7   → 1.00 (no bonus)
  /// - streakDays >= 7  → 1.05 (+5%)
  /// - streakDays >= 30 → 1.10 (+10%)
  /// - streakDays >= 100→ 1.15 (+15%)
  double streakMultiplier(int streakDays) {
    if (streakDays >= 100) return 1.15;
    if (streakDays >= 30) return 1.10;
    if (streakDays >= 7) return 1.05;
    return 1.0;
  }

  /// Advances state by one day.
  ///
  /// [consistency] should be produced by [effortToConsistency]; lies in
  /// [0, maxDailyConsistency]. Pass [hadEffort] = true if the day's total
  /// effort E > 0, so the repository can correctly advance [HabitState.streakDays].
  ///
  /// The streak multiplier is drawn from [state.streakDays] *before* this day
  /// is counted, reflecting momentum accumulated up to (but not including) today.
  HabitState step(
    HabitState state,
    double consistency, {
    bool hadEffort = false,
    double maxDailyConsistency = maxDailyConsistency,
  }) {
    assert(consistency >= 0.0 && consistency <= maxDailyConsistency + 1e-9);

    final multiplier = streakMultiplier(state.streakDays);

    // Variable decay: high accumulated focus slows momentum loss on missed days.
    final effectiveB = b / (1.0 + resilienceFactor * state.focus);
    assert(effectiveB > 0.0, 'effectiveB must always be positive');

    final nextFocus =
        (state.focus + a * consistency * multiplier - effectiveB * state.focus)
            .clamp(0.0, double.infinity);
    final nextProgress = state.progress + nextFocus;
    final nextStreak = hadEffort ? state.streakDays + 1 : 0;

    return HabitState(
      day: state.day + 1,
      focus: nextFocus,
      progress: nextProgress,
      streakDays: nextStreak,
    );
  }

  /// Projects forward assuming a constant average consistency (e.g. the
  /// user's trailing 7- or 30-day average). Returns the projected day index
  /// at which progress reaches [goal], or null if not within [maxDays].
  ///
  /// [assumedHadEffort] controls whether simulated days are counted as
  /// streak-contributing; defaults to true (assumes the user keeps checking in).
  int? projectCompletionDay({
    required HabitState current,
    required double goal,
    required double assumedConsistency,
    bool assumedHadEffort = true,
    int maxDays = 365,
    double maxDailyConsistency = maxDailyConsistency,
  }) {
    var state = current;
    for (var i = 0; i < maxDays; i++) {
      if (state.progress >= goal) return state.day;
      state = step(
        state,
        assumedConsistency,
        hadEffort: assumedHadEffort,
        maxDailyConsistency: maxDailyConsistency,
      );
    }
    return null;
  }
}
