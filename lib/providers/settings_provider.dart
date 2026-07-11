import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import '../services/notification_service.dart';

/// Manages application settings state.
///
/// Exposes toggles for nudges and daily schedule times, and automatically triggers
/// notification rescheduling upon modification.
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  /// Creates a [SettingsProvider] backed by the given [SettingsRepository].
  SettingsProvider(this._repository);

  /// Returns whether notifications are enabled.
  bool get nudgesEnabled => _repository.nudgesEnabled;

  /// Returns the configured daily notification times.
  List<String> get reminderTimes => _repository.reminderTimes;

  /// Updates whether notifications are enabled and reschedules them.
  Future<void> setNudgesEnabled(bool enabled) async {
    await _repository.setNudgesEnabled(enabled);
    notifyListeners();
    await NotificationService.instance.reschedule();
  }

  /// Updates daily notification times and reschedules them.
  Future<void> setReminderTimes(List<String> times) async {
    await _repository.setReminderTimes(times);
    notifyListeners();
    await NotificationService.instance.reschedule();
  }
}
