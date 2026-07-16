/// Sanity-check script for the habit-progress projection model.
///
/// Usage:
///   dart run tool/habit_model_sanity_check.dart <goalId> [goal] [days]
///
/// Arguments:
///   goalId  (required) — the Hive goal ID to inspect
///   goal    (optional) — progress target for projection, default 100
///   days    (optional) — trailing-consistency window, default 30
///
/// Example:
///   dart run tool/habit_model_sanity_check.dart abc-123 200 14
///
/// Prints day-by-day: date | check-ins | consistency | focus | progress
/// Then prints the projected completion day and calendar date.
///
/// This is a manual inspection tool only — no assertions, no test setup.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/models/habit_model.dart';
import 'package:phantom/repositories/check_in_repository.dart';
import 'package:phantom/repositories/goal_repository.dart';
import 'package:phantom/repositories/habit_repository.dart';

Future<void> main(List<String> args) async {
  // ── Arg parsing ────────────────────────────────────────────────────────────
  if (args.isEmpty) {
    print('Usage: dart run tool/habit_model_sanity_check.dart <goalId> [goal] [days]');
    exit(1);
  }

  final goalId = args[0];
  final goal = args.length > 1 ? double.tryParse(args[1]) ?? 100.0 : 100.0;
  final windowDays = args.length > 2 ? int.tryParse(args[2]) ?? 30 : 30;

  // ── Hive init ──────────────────────────────────────────────────────────────
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  Box checkInsBox;
  Box goalsBox;
  try {
    checkInsBox = await Hive.openBox(CheckInRepository.boxName);
    goalsBox = await Hive.openBox(GoalRepository.boxName);
  } catch (e) {
    print('ERROR: Could not open Hive boxes: $e');
    print('Run the app at least once so Hive creates the database files.');
    exit(1);
  }

  final goalRepo = GoalRepository(goalsBox);
  final realGoal = goalRepo.getById(goalId);
  final profile = realGoal?.profile ?? HabitProfile.duration;
  final config = HabitProfileConfig.byProfile[profile] ?? HabitProfileConfig.duration;

  print('═══════════════════════════════════════════════════════════════');
  print('Habit Model Sanity Check');
  print('  goalId  : $goalId');
  print('  title   : ${realGoal?.title ?? 'Unknown'}');
  print('  profile : ${profile.name}');
  print('  goal    : $goal');
  print('  window  : $windowDays days');
  print('═══════════════════════════════════════════════════════════════\n');

  // ── Load real data ──────────────────────────────────────────────────────────
  final checkInRepo = CheckInRepository(checkInsBox);
  final allCheckIns = checkInRepo.getAll();
  final goalCheckIns = allCheckIns.where((c) => c.goalId == goalId).toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  if (goalCheckIns.isEmpty) {
    print('No check-ins found for goalId "$goalId".');
    print('Available goalIds in this database:');
    final goalIds = allCheckIns.map((c) => c.goalId).toSet();
    for (final id in goalIds) {
      print('  • $id');
    }
    await Hive.close();
    exit(0);
  }

  print('Found ${goalCheckIns.length} check-in(s) for goal "$goalId"\n');

  // ── Day-by-day replay ──────────────────────────────────────────────────────
  const habitModel = HabitModel();

  DateTime midnight(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  String fmt(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  // Build weight-per-day map for this goal.
  final effortByDay = <DateTime, double>{};
  for (final c in goalCheckIns) {
    final day = midnight(c.timestamp);
    effortByDay[day] = (effortByDay[day] ?? 0.0) + c.weight;
  }

  final firstDay = effortByDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  final today = midnight(DateTime.now());

  print('${'Date'.padRight(12)} ${'Effort'.padRight(10)} '
      '${'Consistency'.padRight(13)} ${'Focus'.padRight(12)} Progress');
  print('─' * 65);

  var state = HabitState.initial();
  var cursor = firstDay;
  while (!cursor.isAfter(today)) {
    final effort = effortByDay[cursor] ?? 0.0;
    final consistency = HabitModel.effortToConsistency(
      effort,
      maxDailyConsistency: config.maxDailyConsistency,
      effortScale: config.effortScale,
    );
    final hadEffort = effort > 0.0;
    state = habitModel.step(
      state,
      consistency,
      hadEffort: hadEffort,
      maxDailyConsistency: config.maxDailyConsistency,
    );
    print(
      '${fmt(cursor).padRight(12)} '
      '${effort.toStringAsFixed(1).padRight(10)} '
      '${consistency.toStringAsFixed(2).padRight(13)} '
      '${state.focus.toStringAsFixed(4).padRight(12)} '
      '${state.progress.toStringAsFixed(4)}',
    );
    cursor = cursor.add(const Duration(days: 1));
  }

  // ── Trailing consistency ───────────────────────────────────────────────────
  final habitRepo = HabitRepository(
    checkIns: goalCheckIns,
    model: habitModel,
    profileLookup: (id) => profile,
  );
  final trailing = habitRepo.trailingConsistency(goalId, days: windowDays);

  print('\n${'─' * 65}');
  print('Final state    : $state');
  print('Trailing ($windowDays d): ${trailing.toStringAsFixed(4)}');

  // ── Projection ────────────────────────────────────────────────────────────
  final result = habitRepo.projectedCompletionDay(goalId, goal);
  final projected = result.projectedDay;

  print('\nProjection (goal = $goal, trailing consistency = ${trailing.toStringAsFixed(4)}):');
  print('  Confidence   : ${result.label} (${(result.confidence * 100).toStringAsFixed(1)}%)');
  if (projected == null) {
    print('  → Not reachable within 365 days at current consistency.');
  } else {
    final daysFromNow = projected - state.day;
    final projectedDate = today.add(Duration(days: daysFromNow));
    print('  → Completion at model day $projected');
    print('     = approximately ${fmt(projectedDate)} '
        '(${daysFromNow >= 0 ? '+' : ''}$daysFromNow days from today)');
  }

  print('\n═══════════════════════════════════════════════════════════════');
  await Hive.close();
}
