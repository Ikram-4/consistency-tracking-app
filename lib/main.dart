import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:phantom/app.dart';
import 'package:phantom/repositories/goal_repository.dart';
import 'package:phantom/repositories/practice_repository.dart';
import 'package:phantom/repositories/check_in_repository.dart';
import 'package:phantom/repositories/weekly_review_repository.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/providers/practice_provider.dart';
import 'package:phantom/providers/check_in_provider.dart';
import 'package:phantom/providers/stats_provider.dart';
import 'package:phantom/providers/weekly_review_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();

  // Open boxes
  final goalsBox = await Hive.openBox('goals');
  final practicesBox = await Hive.openBox('practices');
  final checkInsBox = await Hive.openBox('check_ins');
  final weeklyReviewsBox = await Hive.openBox('weekly_reviews');

  // Create repositories
  final goalRepo = GoalRepository(goalsBox);
  final practiceRepo = PracticeRepository(practicesBox);
  final checkInRepo = CheckInRepository(checkInsBox);
  final weeklyReviewRepo = WeeklyReviewRepository(weeklyReviewsBox);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GoalProvider(goalRepo, practiceRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => PracticeProvider(practiceRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => CheckInProvider(checkInRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsProvider(checkInRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => WeeklyReviewProvider(weeklyReviewRepo),
        ),
      ],
      child: const PhantomApp(),
    ),
  );
}
