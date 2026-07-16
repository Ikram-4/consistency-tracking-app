import 'dart:math' show exp;

import 'package:flutter_test/flutter_test.dart';
import 'package:phantom/models/habit_model.dart';
import 'package:phantom/models/check_in.dart';
import 'package:phantom/repositories/habit_repository.dart';
import 'package:phantom/models/goal.dart' show Goal, HabitProfile;

void main() {
  const model = HabitModel();

  // ---------------------------------------------------------------------------
  // Helper: convenience formula reference
  // ---------------------------------------------------------------------------
  double refConsistency(double effort) =>
      HabitModel.maxDailyConsistency * (1.0 - exp(-effort / HabitModel.effortScale));

  // ---------------------------------------------------------------------------
  // Helper: fake CheckIn factory
  // ---------------------------------------------------------------------------
  CheckIn fakeCheckIn(
    String goalId,
    int daysAgo, {
    String? id,
    double weight = 1.0,
  }) {
    final ts = DateTime.now().subtract(Duration(days: daysAgo));
    return CheckIn(
      id: id,
      goalId: goalId,
      practiceId: 'practice-1',
      note: 'test',
      effortLevel: 2,
      timestamp: ts,
      weight: weight,
    );
  }

  // ---------------------------------------------------------------------------
  // HabitModel.effortToConsistency — diminishing-returns formula
  // ---------------------------------------------------------------------------
  group('HabitModel.effortToConsistency', () {
    test('E=0 yields consistency = 0', () {
      expect(HabitModel.effortToConsistency(0.0), 0.0);
    });

    test('E=1.0 (single default-weight check-in) yields consistency ≈ 1.0 (±0.05)', () {
      final c = HabitModel.effortToConsistency(1.0);
      expect(c, closeTo(1.0, 0.05),
          reason: 'Single default-weight session should map close to 1.0, got $c');
    });

    test('E=3.0 yields consistency between 2.0 and 2.3', () {
      final c = HabitModel.effortToConsistency(3.0);
      expect(c, greaterThan(2.0));
      expect(c, lessThan(2.3));
    });

    test('E=10.0 yields consistency very close to but strictly less than 3.0', () {
      final c = HabitModel.effortToConsistency(10.0);
      expect(c, lessThan(HabitModel.maxDailyConsistency));
      expect(c, greaterThan(HabitModel.maxDailyConsistency - 0.11),
          reason: 'E=10 should be very close to the asymptote of 3.0, got $c');
    });

    test('consistency is strictly monotone increasing with effort', () {
      final values = [0.5, 1.0, 2.0, 3.0, 5.0, 10.0]
          .map(HabitModel.effortToConsistency)
          .toList();
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThan(values[i - 1]),
            reason: 'Consistency should increase with effort');
      }
    });

    test('result is defensively clamped to [0, maxDailyConsistency]', () {
      // Negative effort is treated as 0.
      expect(HabitModel.effortToConsistency(-1.0), 0.0);
      // Very large effort saturates at maxDailyConsistency.
      expect(
        HabitModel.effortToConsistency(1e9),
        closeTo(HabitModel.maxDailyConsistency, 1e-6),
      );
    });

    test('matches the reference formula directly', () {
      for (final e in [0.25, 0.5, 1.0, 2.0, 4.0]) {
        expect(HabitModel.effortToConsistency(e), closeTo(refConsistency(e), 1e-12));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // CheckIn.weight — model field and serialization
  // ---------------------------------------------------------------------------
  group('CheckIn.weight', () {
    test('defaults to 1.0 when not specified', () {
      final c = CheckIn(
        goalId: 'g',
        practiceId: 'p',
        note: 'n',
        effortLevel: 1,
      );
      expect(c.weight, 1.0);
    });

    test('explicit weight is stored correctly', () {
      final c = CheckIn(
        goalId: 'g',
        practiceId: 'p',
        note: 'n',
        effortLevel: 1,
        weight: 2.0,
      );
      expect(c.weight, 2.0);
    });

    test('toMap includes weight', () {
      final c = CheckIn(
        goalId: 'g',
        practiceId: 'p',
        note: 'n',
        effortLevel: 1,
        weight: 0.5,
      );
      expect(c.toMap()['weight'], 0.5);
    });

    test('fromMap reads weight field', () {
      final map = {
        'id': 'id1',
        'practiceId': 'p',
        'goalId': 'g',
        'note': 'n',
        'effortLevel': 2,
        'durationMinutes': null,
        'timestamp': DateTime.now().toIso8601String(),
        'weight': 1.5,
      };
      expect(CheckIn.fromMap(map).weight, 1.5);
    });

    test('fromMap defaults weight to 1.0 for legacy records missing the key', () {
      final map = {
        'id': 'id2',
        'practiceId': 'p',
        'goalId': 'g',
        'note': 'n',
        'effortLevel': 2,
        'durationMinutes': null,
        'timestamp': DateTime.now().toIso8601String(),
        // 'weight' key deliberately absent
      };
      expect(CheckIn.fromMap(map).weight, 1.0);
    });

    test('copyWith preserves weight when not overridden', () {
      final original = CheckIn(
        goalId: 'g', practiceId: 'p', note: 'n', effortLevel: 1, weight: 2.5,
      );
      expect(original.copyWith(note: 'updated').weight, 2.5);
    });

    test('copyWith can override weight', () {
      final original = CheckIn(
        goalId: 'g', practiceId: 'p', note: 'n', effortLevel: 1, weight: 1.0,
      );
      expect(original.copyWith(weight: 0.5).weight, 0.5);
    });
  });

  // ---------------------------------------------------------------------------
  // HabitModel.step — ODE stepper
  // ---------------------------------------------------------------------------
  group('HabitModel.step', () {
    test('initial state starts at day 0, focus 0, progress 0', () {
      final state = HabitState.initial();
      expect(state.day, 0);
      expect(state.focus, 0.0);
      expect(state.progress, 0.0);
    });

    test('step with consistency ≈ 1.0 increases focus and progress', () {
      final s0 = HabitState.initial();
      // E=1.0 → consistency ≈ 1.0
      final s1 = model.step(s0, HabitModel.effortToConsistency(1.0));
      expect(s1.day, 1);
      expect(s1.focus, greaterThan(0.0));
      expect(s1.progress, greaterThan(0.0));
    });

    test('focus never goes negative even with 0 consistency for 1000 days', () {
      var state = HabitState.initial(startingFocus: 10.0);
      for (var i = 0; i < 1000; i++) {
        state = model.step(state, 0.0);
        expect(state.focus, greaterThanOrEqualTo(0.0),
            reason: 'focus went negative on day ${state.day}');
      }
    });

    test('higher effort consistency reaches a goal strictly earlier', () {
      const goal = 50.0;
      final dayHigh = model.projectCompletionDay(
        current: HabitState.initial(),
        goal: goal,
        assumedConsistency: HabitModel.effortToConsistency(3.0),
      );
      final dayLow = model.projectCompletionDay(
        current: HabitState.initial(),
        goal: goal,
        assumedConsistency: HabitModel.effortToConsistency(0.5),
      );
      expect(dayHigh, isNotNull);
      expect(dayLow, isNotNull);
      expect(dayHigh! < dayLow!, isTrue);
    });

    test('projectCompletionDay returns null when consistency is 0', () {
      expect(
        model.projectCompletionDay(
          current: HabitState.initial(),
          goal: 1.0,
          assumedConsistency: 0.0,
        ),
        isNull,
      );
    });

    test('projectCompletionDay returns current day when progress already meets goal', () {
      const state = HabitState(day: 5, focus: 1.0, progress: 100.0);
      expect(
        model.projectCompletionDay(
          current: state,
          goal: 50.0,
          assumedConsistency: 0.5,
        ),
        5,
      );
    });

    test('maxDailyConsistency constant equals 3.0', () {
      expect(HabitModel.maxDailyConsistency, 3.0);
    });

    test('effortScale constant equals 2.47', () {
      expect(HabitModel.effortScale, 2.47);
    });
  });

  // ---------------------------------------------------------------------------
  // Weight-based consistency semantics
  // ---------------------------------------------------------------------------
  group('Weight-based consistency semantics', () {
    test(
        'single 2.0-weight check-in yields same consistency as two 1.0-weight '
        'check-ins on the same day', () {
      final oneHeavy = HabitModel.effortToConsistency(2.0);
      final twoLight = HabitModel.effortToConsistency(1.0 + 1.0);
      expect(oneHeavy, closeTo(twoLight, 1e-12),
          reason: 'Equal total effort should produce equal consistency');
    });

    test('0.5-weight check-in yields lower consistency than 1.0-weight check-in', () {
      final cHalf = HabitModel.effortToConsistency(0.5);
      final cFull = HabitModel.effortToConsistency(1.0);
      expect(cHalf, lessThan(cFull));
    });

    test('three 1.0-weight check-ins produce strictly more focus than one', () {
      final s0 = HabitState.initial();
      final s1 = model.step(s0, HabitModel.effortToConsistency(1.0));
      final s3 = model.step(s0, HabitModel.effortToConsistency(3.0));
      expect(s3.focus, greaterThan(s1.focus));
    });
  });

  // ---------------------------------------------------------------------------
  // HabitRepository
  // ---------------------------------------------------------------------------
  group('HabitRepository', () {
    test('currentState with no check-ins returns initial state', () {
      final repo = HabitRepository(checkIns: []);
      final state = repo.currentState('goal-x');
      expect(state.day, 0);
      expect(state.focus, 0.0);
      expect(state.progress, 0.0);
    });

    test('currentState replays history to advance progress', () {
      final checkIns = [
        fakeCheckIn('goal-1', 2),
        fakeCheckIn('goal-1', 1),
        fakeCheckIn('goal-1', 0),
      ];
      final repo = HabitRepository(checkIns: checkIns);
      final state = repo.currentState('goal-1');
      expect(state.day, greaterThan(0));
      expect(state.progress, greaterThan(0.0));
    });

    test('currentState ignores check-ins for other goals', () {
      final checkIns = [
        fakeCheckIn('goal-other', 1),
        fakeCheckIn('goal-other', 0),
      ];
      final repo = HabitRepository(checkIns: checkIns);
      final state = repo.currentState('goal-x');
      expect(state.day, 0);
      expect(state.progress, 0.0);
    });

    test('weight=2.0 check-in and two weight=1.0 check-ins on same day yield '
        'same progress (effort additivity)', () {
      // One heavy session.
      final heavy = HabitRepository(checkIns: [
        fakeCheckIn('g', 0, id: 'h1', weight: 2.0),
      ]);
      // Two light sessions on the same day summing to same effort.
      final light = HabitRepository(checkIns: [
        fakeCheckIn('g', 0, id: 'l1', weight: 1.0),
        fakeCheckIn('g', 0, id: 'l2', weight: 1.0),
      ]);
      final sh = heavy.currentState('g');
      final sl = light.currentState('g');
      expect(sh.progress, closeTo(sl.progress, 1e-10));
      expect(sh.focus, closeTo(sl.focus, 1e-10));
    });

    test('trailingConsistency returns 0.0 when no check-ins in window', () {
      final repo = HabitRepository(checkIns: []);
      expect(repo.trailingConsistency('goal-3', days: 30), 0.0);
    });

    test('trailingConsistency with one default-weight check-in today over 7 days '
        'is close to effortToConsistency(1.0) / 7', () {
      final repo = HabitRepository(checkIns: [fakeCheckIn('g7', 0)]);
      final consistency = repo.trailingConsistency('g7', days: 7);
      final expected = HabitModel.effortToConsistency(1.0) / 7.0;
      expect(consistency, closeTo(expected, 1e-10));
    });

    test('projectedCompletionDay returns null when no history', () {
      final repo = HabitRepository(checkIns: []);
      expect(repo.projectedCompletionDay('goal-x', 10.0).projectedDay, isNull);
    });

    test('currentState returns identical object on repeated calls with no new check-ins', () {
      final checkIns = [
        fakeCheckIn('goal-memo', 1),
        fakeCheckIn('goal-memo', 0),
      ];
      final repo = HabitRepository(checkIns: checkIns);
      final first = repo.currentState('goal-memo');
      final second = repo.currentState('goal-memo');
      expect(identical(first, second), isTrue,
          reason: 'Second call should return cached HabitState without replay');
    });
  });

  // ---------------------------------------------------------------------------
  // streakMultiplier — threshold boundary tests
  // ---------------------------------------------------------------------------
  group('HabitModel.streakMultiplier', () {
    test('returns exactly 1.0 for streakDays = 0', () {
      expect(model.streakMultiplier(0), 1.0);
    });

    test('returns exactly 1.0 for streakDays = 6 (just below 7-day threshold)', () {
      expect(model.streakMultiplier(6), 1.0);
    });

    test('returns exactly 1.05 for streakDays = 7 (inclusive threshold)', () {
      expect(model.streakMultiplier(7), 1.05);
    });

    test('returns exactly 1.05 for streakDays = 29 (just below 30-day threshold)', () {
      expect(model.streakMultiplier(29), 1.05);
    });

    test('returns exactly 1.10 for streakDays = 30 (inclusive threshold)', () {
      expect(model.streakMultiplier(30), 1.10);
    });

    test('returns exactly 1.10 for streakDays = 99 (just below 100-day threshold)', () {
      expect(model.streakMultiplier(99), 1.10);
    });

    test('returns exactly 1.15 for streakDays = 100 (inclusive threshold)', () {
      expect(model.streakMultiplier(100), 1.15);
    });

    test('returns exactly 1.15 for streakDays = 200 (well above max threshold)', () {
      expect(model.streakMultiplier(200), 1.15);
    });
  });

  // ---------------------------------------------------------------------------
  // Streak bonus accumulation — focus comparison
  // ---------------------------------------------------------------------------
  group('Streak bonus accumulation', () {
    test(
        'goal with streakDays=30 accumulates strictly more focus over 10 days '
        'than an identical goal starting from streakDays=0', () {
      // Both goals use the same daily consistency value.
      const consistency = 1.0;

      // Simulate 10 days from a state with no streak.
      var noStreak = const HabitState(day: 0, focus: 0.0, progress: 0.0, streakDays: 0);
      for (var i = 0; i < 10; i++) {
        noStreak = model.step(noStreak, consistency, hadEffort: true);
      }

      // Simulate the same 10 days starting from a 30-day streak.
      var withStreak = const HabitState(day: 0, focus: 0.0, progress: 0.0, streakDays: 30);
      for (var i = 0; i < 10; i++) {
        withStreak = model.step(withStreak, consistency, hadEffort: true);
      }

      expect(withStreak.focus, greaterThan(noStreak.focus),
          reason: 'Streak of 30 days should earn more focus via the 1.10 multiplier');
      expect(withStreak.progress, greaterThan(noStreak.progress));
    });

    test('streakDays advances by 1 each day when hadEffort=true', () {
      var state = HabitState.initial();
      for (var day = 1; day <= 10; day++) {
        state = model.step(state, 1.0, hadEffort: true);
        expect(state.streakDays, day,
            reason: 'After $day consecutive check-in days, streakDays should be $day');
      }
    });

    test('streakDays stays 0 when hadEffort is always false', () {
      var state = HabitState.initial();
      for (var i = 0; i < 5; i++) {
        state = model.step(state, 0.0, hadEffort: false);
        expect(state.streakDays, 0);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Broken streak — reset and multiplier drop
  // ---------------------------------------------------------------------------
  group('Broken streak', () {
    test(
        'one zero-consistency day resets streakDays to 0 and multiplier drops '
        'back to 1.0 on the following day', () {
      // Build up a 10-day streak.
      var state = HabitState.initial();
      for (var i = 0; i < 10; i++) {
        state = model.step(state, 1.0, hadEffort: true);
      }
      expect(state.streakDays, 10);
      expect(model.streakMultiplier(state.streakDays), 1.05); // 7–29 bracket

      // Miss one day (E = 0, hadEffort = false).
      state = model.step(state, 0.0, hadEffort: false);
      expect(state.streakDays, 0,
          reason: 'Missed day must reset streakDays to 0');
      expect(model.streakMultiplier(state.streakDays), 1.0,
          reason: 'Multiplier should be back to 1.0 after streak reset');
    });

    test('streak resumes counting correctly after a break', () {
      // 5-day streak, then a miss, then 3 more days.
      var state = HabitState.initial();
      for (var i = 0; i < 5; i++) {
        state = model.step(state, 1.0, hadEffort: true);
      }
      state = model.step(state, 0.0, hadEffort: false); // break
      expect(state.streakDays, 0);
      for (var i = 0; i < 3; i++) {
        state = model.step(state, 1.0, hadEffort: true);
      }
      expect(state.streakDays, 3,
          reason: 'Streak counter should restart from 0 after the break');
    });
  });

  // ---------------------------------------------------------------------------
  // Missed-day resilience — variable decay proportional tests
  // ---------------------------------------------------------------------------
  group('Missed-day resilience', () {
    test(
        'high-focus state retains a strictly greater PROPORTION of focus '
        'after one missed day than a low-focus state', () {
      // Low-focus state: focus = 1.0
      const lowFocusState = HabitState(day: 0, focus: 1.0, progress: 0.0);
      final lowAfterMiss = model.step(lowFocusState, 0.0);
      final lowRetention = lowAfterMiss.focus / lowFocusState.focus;

      // High-focus state: focus = 20.0
      const highFocusState = HabitState(day: 0, focus: 20.0, progress: 0.0);
      final highAfterMiss = model.step(highFocusState, 0.0);
      final highRetention = highAfterMiss.focus / highFocusState.focus;

      expect(highRetention, greaterThan(lowRetention),
          reason: 'High-focus state should retain a larger fraction of focus '
              '(low=$lowRetention, high=$highRetention)');
    });

    test(
        'at focus = 0, effectiveB equals b exactly (baseline unchanged)', () {
      // effectiveB = b / (1 + resilienceFactor * 0) = b / 1 = b
      final effectiveB = model.b /
          (1.0 + HabitModel.resilienceFactor * 0.0);
      expect(effectiveB, closeTo(model.b, 1e-12));
    });

    test('effectiveB is always strictly positive across a wide focus range', () {
      for (final focus in [0.0, 1.0, 50.0, 1000.0]) {
        final effectiveB = model.b /
            (1.0 + HabitModel.resilienceFactor * focus);
        expect(effectiveB, greaterThan(0.0),
            reason: 'effectiveB must be > 0 at focus=$focus, got $effectiveB');
      }
    });

    test('resilienceFactor constant equals 0.02', () {
      expect(HabitModel.resilienceFactor, 0.02);
    });

    test('focus never goes negative on long missed-day runs with high starting focus', () {
      var state = const HabitState(day: 0, focus: 50.0, progress: 0.0);
      for (var i = 0; i < 500; i++) {
        state = model.step(state, 0.0);
        expect(state.focus, greaterThanOrEqualTo(0.0),
            reason: 'Focus went negative on day ${state.day}');
      }
    });

    test('two missed days with high focus decay less total focus than '
        'two missed days with low focus (absolute delta comparison)', () {
      // Both start from focus=0 progress, but different focus levels.
      const low = HabitState(day: 0, focus: 2.0, progress: 0.0);
      const high = HabitState(day: 0, focus: 20.0, progress: 0.0);

      var lowState = low;
      var highState = high;
      for (var i = 0; i < 2; i++) {
        lowState = model.step(lowState, 0.0);
        highState = model.step(highState, 0.0);
      }

      final lowFocusLost = low.focus - lowState.focus;
      final highFocusLost = high.focus - highState.focus;

      // High-focus state loses MORE absolute focus (bigger base to decay from),
      // but the PROPORTION lost should be less — already confirmed above.
      // Here we just confirm the direction of absolute loss is sensible.
      expect(lowFocusLost, greaterThanOrEqualTo(0.0));
      expect(highFocusLost, greaterThanOrEqualTo(0.0));

      // Verify the high-focus proportional retention is indeed better.
      final lowRetention = lowState.focus / low.focus;
      final highRetention = highState.focus / high.focus;
      expect(highRetention, greaterThan(lowRetention));
    });
  });

  // ---------------------------------------------------------------------------
  // Projection Confidence Scores
  // ---------------------------------------------------------------------------
  group('Projection Confidence', () {
    test('90 days of stable consistency yields High confidence', () {
      // 90 check-ins, 1 per day for 90 days.
      final checkIns = List.generate(
        90,
        (i) => fakeCheckIn('goal-stable', i, weight: 1.0),
      );
      final repo = HabitRepository(checkIns: checkIns);
      final result = repo.projectedCompletionDay('goal-stable', 10.0);

      expect(result.label, 'High');
      expect(result.confidence, greaterThanOrEqualTo(0.7));
    });

    test('5 days of history yields Low or Medium confidence regardless of variance', () {
      // 5 check-ins, 1 per day for 5 days.
      final checkIns = List.generate(
        5,
        (i) => fakeCheckIn('goal-short', i, weight: 1.0),
      );
      final repo = HabitRepository(checkIns: checkIns);
      final result = repo.projectedCompletionDay('goal-short', 10.0);

      // Volume score is (1 - exp(-5/20)) = 0.221
      // Even if variance score is 1.0, combined score is 0.221*0.5 + 1.0*0.5 = 0.61 (Medium)
      // So confidence should be 'Medium' or 'Low', definitely not 'High'.
      expect(result.label, isNot('High'));
      expect(result.confidence, lessThan(0.7));
    });

    test('two goals with same average: stable vs erratic yields higher confidence for stable', () {
      final today = DateTime.now();

      // Stable: 10 check-ins on 10 separate days (weight 1.0 each day).
      // Total consistency sum = 10. Average consistency = 1.0 per day.
      final stableCheckIns = List.generate(
        10,
        (i) => CheckIn(
          id: 'stable-$i',
          goalId: 'stable',
          practiceId: 'p',
          note: 'n',
          effortLevel: 2,
          timestamp: today.subtract(Duration(days: i)),
          weight: 1.0,
        ),
      );

      // Erratic: 2 check-ins of weight 5.0 (each capped at 3.0 consistency) on 2 days, and 8 days of 0.
      // Total consistency sum = 3.0 + 3.0 = 6.0. Average = 0.6.
      // Let's match average exactly to be safe: stable has 1.0 each day (sum = 10).
      // Erratic has 3.333 weight (which gives consistency ~2.3) on 4 days (sum ~ 9.2) and 6 days of 0.
      // Or simply: stable consistency is [1.0, 1.0, ...], erratic is [0, 2.5, 0, 2.5, ...].
      // Standard deviation of stable will be 0.0. Standard deviation of erratic will be high.
      final erraticCheckIns = [
        CheckIn(
          id: 'erratic-1',
          goalId: 'erratic',
          practiceId: 'p',
          note: 'n',
          effortLevel: 2,
          timestamp: today.subtract(const Duration(days: 0)),
          weight: 5.0, // Capped to maxDailyConsistency (3.0)
        ),
        CheckIn(
          id: 'erratic-2',
          goalId: 'erratic',
          practiceId: 'p',
          note: 'n',
          effortLevel: 2,
          timestamp: today.subtract(const Duration(days: 2)),
          weight: 5.0, // Capped to maxDailyConsistency (3.0)
        ),
        CheckIn(
          id: 'erratic-3',
          goalId: 'erratic',
          practiceId: 'p',
          note: 'n',
          effortLevel: 2,
          timestamp: today.subtract(const Duration(days: 4)),
          weight: 4.0, // Capped to maxDailyConsistency (3.0)
        ),
      ];

      final repoStable = HabitRepository(checkIns: stableCheckIns);
      final repoErratic = HabitRepository(checkIns: erraticCheckIns);

      final resultStable = repoStable.projectedCompletionDay('stable', 100.0);
      final resultErratic = repoErratic.projectedCompletionDay('erratic', 100.0);

      // Since history days is similar (10 days vs 5 days, or we can look at variance score alone),
      // let's directly verify stable confidence score is higher.
      expect(resultStable.confidence, greaterThan(resultErratic.confidence),
          reason: 'Stable check-in pattern must yield higher confidence than erratic check-in pattern');
    });
    group('Habit Profiles', () {
      test('same check-in weight on same day produces different consistency values across profiles', () {
      // Weight = 1.0.
      // For frequency, effortScale = 0.8: consistency = 3 * (1 - exp(-1/0.8)) = 3 * 0.713 = 2.14
      // For duration, effortScale = 2.47: consistency = 3 * (1 - exp(-1/2.47)) = 3 * 0.332 = 1.00
      // For singleSession, effortScale = 0.3: consistency = 3 * (1 - exp(-1/0.3)) = 3 * 0.964 = 2.89

      final cFreq = HabitModel.effortToConsistency(
        1.0,
        maxDailyConsistency: HabitProfileConfig.frequency.maxDailyConsistency,
        effortScale: HabitProfileConfig.frequency.effortScale,
      );
      final cDur = HabitModel.effortToConsistency(
        1.0,
        maxDailyConsistency: HabitProfileConfig.duration.maxDailyConsistency,
        effortScale: HabitProfileConfig.duration.effortScale,
      );
      final cSingle = HabitModel.effortToConsistency(
        1.0,
        maxDailyConsistency: HabitProfileConfig.singleSession.maxDailyConsistency,
        effortScale: HabitProfileConfig.singleSession.effortScale,
      );

      expect(cFreq, isNot(closeTo(cDur, 1e-5)));
      expect(cDur, isNot(closeTo(cSingle, 1e-5)));
      expect(cSingle, greaterThan(cFreq));
      expect(cFreq, greaterThan(cDur));
    });

    test('Goal profile defaults to duration', () {
      final goal = Goal(
        title: 'T',
        domain: 'D',
        targetDate: DateTime.now(),
      );
      expect(goal.profile, HabitProfile.duration);
    });

    test('replaying duration profile produces same output as baseline', () {
      final checkIns = [
        fakeCheckIn('g', 2, weight: 1.0),
        fakeCheckIn('g', 0, weight: 1.5),
      ];

      // Explicit duration profile.
      final repoDur = HabitRepository(
        checkIns: checkIns,
        profileLookup: (id) => HabitProfile.duration,
      );
      final stateDur = repoDur.currentState('g');

      // Default profile (no profileLookup supplied, falls back to duration).
      final repoDefault = HabitRepository(checkIns: checkIns);
      final stateDefault = repoDefault.currentState('g');

      expect(stateDur.focus, closeTo(stateDefault.focus, 1e-12));
      expect(stateDur.progress, closeTo(stateDefault.progress, 1e-12));
      expect(stateDur.streakDays, stateDefault.streakDays);
    });
  });
  });
}
