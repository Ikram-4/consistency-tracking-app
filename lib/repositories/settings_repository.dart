import 'package:hive/hive.dart';

/// Repository for managing application settings in Hive.
///
/// Encapsulates all Hive operations for settings to comply with architectural constraints.
class SettingsRepository {
  final Box _box;

  /// Creates a [SettingsRepository] backed by the given [Box].
  SettingsRepository(this._box);

  /// Returns whether reminders are enabled (default is true).
  bool get nudgesEnabled => _box.get('nudges_enabled', defaultValue: true) as bool;

  /// Updates the status of reminders.
  Future<void> setNudgesEnabled(bool enabled) async {
    await _box.put('nudges_enabled', enabled);
  }

  /// Returns the daily reminder times in HH:MM format (default: 4pm, 7pm, 10pm).
  List<String> get reminderTimes {
    final raw = _box.get('reminder_times', defaultValue: ['16:00', '19:00', '22:00']);
    return List<String>.from(raw as List);
  }

  /// Updates the daily reminder times.
  Future<void> setReminderTimes(List<String> times) async {
    await _box.put('reminder_times', times);
  }
}
