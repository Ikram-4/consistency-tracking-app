import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

/// Screen for managing application settings, specifically notification times and preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _exactAlarmsAllowed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExactAlarms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExactAlarms();
    }
  }

  Future<void> _checkExactAlarms() async {
    final allowed = await NotificationService.instance.canScheduleExactAlarms();
    if (mounted) {
      setState(() {
        _exactAlarmsAllowed = allowed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final times = settingsProvider.reminderTimes;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // General Notification Toggle Card
              Container(
                decoration: AppTheme.elevatedDecoration(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Daily Accountability Nudges',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppTheme.dataWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Receive notification prompts when active practices are behind pace.',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  activeColor: AppTheme.onTrack,
                  activeTrackColor: AppTheme.onTrack.withOpacity(0.2),
                  inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(0.4),
                  inactiveTrackColor: theme.colorScheme.surface,
                  value: settingsProvider.nudgesEnabled,
                  onChanged: (value) => settingsProvider.setNudgesEnabled(value),
                ),
              ),

              // Exact Alarms Warning Banner
              if (settingsProvider.nudgesEnabled && !_exactAlarmsAllowed) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: AppTheme.elevatedDecoration().copyWith(
                    border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Exact Reminders Disabled',
                              style: textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Exact reminder times are restricted by Android battery optimizations. Alarms may be delayed. Enable them in your device settings to get timely nudges.',
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Allow Exact Alarms'),
                        onPressed: () async {
                          await NotificationService.instance.requestExactAlarmsPermission();
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (settingsProvider.nudgesEnabled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Reminder Times',
                      style: textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${times.length} of 3 scheduled',
                      style: textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Times List
                ...times.asMap().entries.map((entry) {
                  final index = entry.key;
                  final timeStr = entry.value;

                  // Parse time for formatted display
                  final parts = timeStr.split(':');
                  final hour = int.parse(parts[0]);
                  final minute = int.parse(parts[1]);
                  final timeOfDay = TimeOfDay(hour: hour, minute: minute);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      decoration: AppTheme.elevatedDecoration(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => _pickTime(context, settingsProvider, index, timeOfDay),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    timeOfDay.format(context),
                                    style: textTheme.titleMedium?.copyWith(
                                      color: AppTheme.dataWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit Time',
                                onPressed: () => _pickTime(context, settingsProvider, index, timeOfDay),
                              ),
                              if (times.length > 1)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete Time',
                                  onPressed: () {
                                    final newTimes = List<String>.from(times)..removeAt(index);
                                    settingsProvider.setReminderTimes(newTimes);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Add Time Button
                if (times.length < 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Reminder Time'),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 00),
                          builder: (context, child) => _buildTimePickerTheme(theme, child!),
                        );

                        if (!context.mounted) return;

                        if (picked != null) {
                          final hourStr = picked.hour.toString().padLeft(2, '0');
                          final minuteStr = picked.minute.toString().padLeft(2, '0');
                          final newTime = '$hourStr:$minuteStr';

                          // Avoid duplicates
                          if (!times.contains(newTime)) {
                            final newTimes = List<String>.from(times)..add(newTime);
                            newTimes.sort(); // Sort times chronologically
                            settingsProvider.setReminderTimes(newTimes);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This reminder time is already scheduled.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: AppTheme.dataWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('Send Test Alert (Instant)'),
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await NotificationService.instance.showInstantTestNotification();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Test alert sent! Check your notification tray.'),
                          backgroundColor: AppTheme.onTrack,
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Notification failed: $e'),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: AppTheme.dataWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Schedule Diagnostic Alarm (2 Min Out)'),
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await NotificationService.instance.scheduleDiagnosticAlarm2MinOut();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Diagnostic alarm scheduled 2 minutes out! Close the app to test background delivery.'),
                          backgroundColor: AppTheme.onTrack,
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to schedule: $e'),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    SettingsProvider provider,
    int index,
    TimeOfDay initialTime,
  ) async {
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => _buildTimePickerTheme(theme, child!),
    );

    if (!context.mounted) return;

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      final newTime = '$hourStr:$minuteStr';

      final times = provider.reminderTimes;
      // If editing to a duplicate that is at a different index, reject
      final duplicateIndex = times.indexOf(newTime);
      if (duplicateIndex != -1 && duplicateIndex != index) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This reminder time is already scheduled.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final newTimes = List<String>.from(times)..[index] = newTime;
      newTimes.sort();
      provider.setReminderTimes(newTimes);
    }
  }

  Widget _buildTimePickerTheme(ThemeData theme, Widget child) {
    return Theme(
      data: theme.copyWith(
        timePickerTheme: theme.timePickerTheme.copyWith(
          backgroundColor: theme.colorScheme.surface,
        ),
      ),
      child: child,
    );
  }
}
