import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/practice.dart';
import '../repositories/goal_repository.dart';
import '../repositories/practice_repository.dart';
import '../repositories/check_in_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/pace_calculator.dart';
import '../utils/streak_calculator.dart';

/// Singleton service managing all local accountability notification nudges.
///
/// Implements timezone-aware scheduling (IST-hardcoded), dynamic practice pacing checks,
/// and priority-based streak-aware quote generation.
class NotificationService {
  NotificationService._();

  /// Singleton instance of the [NotificationService].
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  late final GoalRepository _goalRepo;
  late final PracticeRepository _practiceRepo;
  late final CheckInRepository _checkInRepo;
  late final SettingsRepository _settingsRepo;

  bool _isInitialized = false;

  /// Initializes local notifications, sets up iOS foreground delegates,
  /// and requests platform alarm permissions.
  Future<void> initialize({
    required GoalRepository goalRepo,
    required PracticeRepository practiceRepo,
    required CheckInRepository checkInRepo,
    required SettingsRepository settingsRepo,
  }) async {
    if (_isInitialized) return;

    _goalRepo = goalRepo;
    _practiceRepo = practiceRepo;
    _checkInRepo = checkInRepo;
    _settingsRepo = settingsRepo;

    // iOS Initialization: Request permissions for Alert, Badge, and Sound
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Try initializing with custom @mipmap/launcher_icon, fallback to stock @mipmap/ic_launcher if missing
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _notificationsPlugin.initialize(initSettings);
    } catch (e) {
      debugPrint('CRITICAL WARNING: Custom @mipmap/launcher_icon failed to load. Falling back to stock @mipmap/ic_launcher. Error: $e');
      try {
        const fallbackAndroidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const fallbackInitSettings = InitializationSettings(android: fallbackAndroidSettings, iOS: iosSettings);
        await _notificationsPlugin.initialize(fallbackInitSettings);
      } catch (e2) {
        debugPrint('CRITICAL ERROR: Failed to initialize notifications altogether: $e2');
        return; // Complete failure to initialize native bindings
      }
    }

    // Request permissions on Android 13+ and exact alarms on Android 12+
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (e) {
          debugPrint('Failed to request exact alarms permission: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
    }

    _isInitialized = true;
  }

  /// Checks if exact alarm scheduling is currently allowed.
  Future<bool> canScheduleExactAlarms() async {
    if (!_isInitialized) return false;
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final allowed = await androidPlugin.canScheduleExactNotifications();
      debugPrint('Exact alarms permission checked. Allowed value: $allowed');
      return allowed ?? false;
    }
    return true; // Non-Android platforms don't restrict exact alarms
  }

  /// Requests the user to allow exact alarms by launching the system settings page.
  Future<void> requestExactAlarmsPermission() async {
    if (!_isInitialized) return;
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// Cancels all notifications scheduled for today (IDs 100, 101, 102).
  Future<void> cancelTodayReminders() async {
    if (!_isInitialized) return;
    await _notificationsPlugin.cancel(100);
    await _notificationsPlugin.cancel(101);
    await _notificationsPlugin.cancel(102);
  }

  /// Reschedules notifications for today and tomorrow.
  ///
  /// Reminder times ALWAYS fire a notification. If practices are behind pace,
  /// the message highlights which ones need attention. If all practices are
  /// on track, an encouraging "you're on track" message is sent instead.
  Future<void> reschedule() async {
    if (!_isInitialized) return;

    try {
      // If nudges are disabled, cancel all slots and return
      if (!_settingsRepo.nudgesEnabled) {
        await cancelTodayReminders();
        await _notificationsPlugin.cancel(200);
        await _notificationsPlugin.cancel(201);
        await _notificationsPlugin.cancel(202);
        return;
      }

      final now = tz.TZDateTime.now(tz.local);
      final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);

      final checkIns = _checkInRepo.getAll();
      final activePractices = _practiceRepo.getActive();
      final activeGoals = _goalRepo.getActive();

      // Use shared standings calculator
      final summary = PaceCalculator.calculateStandings(
        activeGoals: activeGoals,
        activePractices: activePractices,
        checkIns: checkIns,
        now: now,
        getGoalById: (id) => _goalRepo.getById(id),
      );

      final behindPractices = summary.behindPractices;
      final int behindCount = behindPractices.length;
      final List<String> times = _settingsRepo.reminderTimes; // e.g. ["16:00", "19:00", "22:00"]

      // Android Specific details
      const androidDetails = AndroidNotificationDetails(
        'nudge_channel_id',
        'Daily Accountability Nudges',
        channelDescription: 'Sends reminders when your practices are behind pace.',
        importance: Importance.high,
        priority: Priority.high,
      );

      // iOS Specific details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // 3. Schedule Today and Tomorrow one-off alarms for EVERY configured time
      for (int i = 0; i < times.length; i++) {
        String title;
        String body;

        if (i < behindCount) {
          // This slot has a behind practice to nudge about
          final practice = behindPractices[i];
          // Use shared streak calculator
          final streak = calculateStreak(practice.id, checkIns, now);
          title = 'Practice Reminder';
          body = _getNudgeMessage(practice, streak);

          // Suffix grouping for the 3rd slot if more than 3 practices are behind
          if (i == 2 && behindCount > 3) {
            body += ' ...and ${behindCount - 3} more practices need attention today.';
          }
        } else {
          // All practices on track — send an encouraging message
          title = 'Daily Check-in';
          body = _getOnTrackMessage(activePractices.length);
        }

        final timeParts = times[i].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Schedule for Today
        final todayAlarm = tz.TZDateTime(tz.local, today.year, today.month, today.day, hour, minute);
        if (todayAlarm.isAfter(now)) {
          debugPrint('Scheduling reminder at $todayAlarm (today slot ${100 + i}): $body');
          try {
            await _notificationsPlugin.zonedSchedule(
              100 + i, // Today Slot ID
              title,
              body,
              todayAlarm,
              details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            );
          } catch (e) {
            // Fallback to inexact scheduling if exact alarm permission is not granted/throws
            debugPrint('Failed to schedule exact notification, falling back to inexact: $e');
            await _notificationsPlugin.zonedSchedule(
              100 + i,
              title,
              body,
              todayAlarm,
              details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
        } else {
          await _notificationsPlugin.cancel(100 + i); // Clear elapsed slot
        }

        // Schedule for Tomorrow
        final tomorrowAlarm = todayAlarm.add(const Duration(days: 1));
        debugPrint('Scheduling reminder at $tomorrowAlarm (tomorrow slot ${200 + i}): $body');
        try {
          await _notificationsPlugin.zonedSchedule(
            200 + i, // Tomorrow Slot ID
            title,
            body,
            tomorrowAlarm,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e) {
          // Fallback to inexact scheduling
          debugPrint('Failed to schedule exact notification for tomorrow, falling back to inexact: $e');
          await _notificationsPlugin.zonedSchedule(
            200 + i,
            title,
            body,
            tomorrowAlarm,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }

      // Cancel any leftover slots beyond what's configured (e.g. user removed a time)
      for (int i = times.length; i < 3; i++) {
        await _notificationsPlugin.cancel(100 + i);
        await _notificationsPlugin.cancel(200 + i);
      }
    } catch (e) {
      // Catch all notification errors to protect app from crashing on start/check-ins
      debugPrint('Notification rescheduling failed: $e');
    }
  }

  /// Returns an encouraging message when all practices are on track.
  String _getOnTrackMessage(int practiceCount) {
    final messages = [
      "You're on track today! Keep the momentum going.",
      "All practices are on pace this week. Consistency is your superpower.",
      "Great progress! You're meeting your targets — don't let up.",
      "On track. Open Phantom to log today's session.",
      "You're crushing it this week. Log a check-in to keep the streak alive.",
    ];
    // Rotate daily so it doesn't feel stale
    final dayIndex = DateTime.now().day % messages.length;
    return messages[dayIndex];
  }



  String _getNudgeMessage(Practice practice, int streak) {
    if (streak >= 14) {
      final quotes = [
        "You've hit $streak days of ${practice.title}. Keep building this momentum today.",
        "Keep it up! You are on a $streak-day streak of ${practice.title}.",
        "Outstanding! $streak days of ${practice.title} complete. Keep pushing today."
      ];
      return quotes[practice.id.hashCode.abs() % quotes.length];
    } else if (streak >= 3) {
      final quotes = [
        "Don't break your $streak-day streak for ${practice.title}!",
        "Don't break your $streak-day streak. Practice ${practice.title} today.",
        "Your $streak-day streak of ${practice.title} is at risk today. Practice now!"
      ];
      return quotes[practice.id.hashCode.abs() % quotes.length];
    } else {
      final quotes = [
        "Log a quick note for your ${practice.title} practice. Small steps build consistency.",
        "Practice ${practice.title} today. Consistency is earned daily.",
        "Every session counts. Take a moment to practice ${practice.title} today."
      ];
      return quotes[practice.id.hashCode.abs() % quotes.length];
    }
  }

  /// Displays an instant test notification to check OS settings and permissions.
  Future<void> showInstantTestNotification() async {
    if (!_isInitialized) throw Exception('NotificationService is not initialized.');

    const androidDetails = AndroidNotificationDetails(
      'nudge_channel_id',
      'Daily Accountability Nudges',
      channelDescription: 'Sends reminders when your practices are behind pace.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      999, // Test Notification ID
      'Phantom System Diagnostic',
      'Test Alert: Permissions and channels are properly configured!',
      details,
    );
  }

  /// Schedules a diagnostic alarm 2 minutes in the future using the exact same production configurations.
  Future<void> scheduleDiagnosticAlarm2MinOut() async {
    if (!_isInitialized) throw Exception('NotificationService is not initialized.');

    final now = tz.TZDateTime.now(tz.local);
    final targetTime = now.add(const Duration(minutes: 2));

    const androidDetails = AndroidNotificationDetails(
      'nudge_channel_id',
      'Daily Accountability Nudges',
      channelDescription: 'Sends reminders when your practices are behind pace.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    const body = 'Diagnostic Test: This fires 2 minutes out using the production zonedSchedule path!';

    try {
      debugPrint('Attempting to schedule exact diagnostic alarm at $targetTime...');
      await _notificationsPlugin.zonedSchedule(
        998, // Diagnostic alarm ID
        'Phantom Diagnostic',
        body,
        targetTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Diagnostic exact alarm successfully scheduled at $targetTime.');
    } catch (e) {
      debugPrint('FALLBACK TRIGGERED: Failed to schedule exact diagnostic alarm: $e. Falling back to inexact alarm.');
      await _notificationsPlugin.zonedSchedule(
        998,
        'Phantom Diagnostic',
        body,
        targetTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Diagnostic inexact alarm fallback successfully scheduled at $targetTime.');
    }
  }
}
