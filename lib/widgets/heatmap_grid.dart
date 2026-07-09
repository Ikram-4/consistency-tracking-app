import 'package:flutter/material.dart';
import 'package:phantom/models/check_in.dart';
import 'package:phantom/utils/date_helpers.dart';
import 'package:phantom/utils/constants.dart';

/// A GitHub-style contribution grid displaying activity consistency.
class HeatmapGrid extends StatelessWidget {
  final List<CheckIn> checkIns;
  final int weeksToShow;

  const HeatmapGrid({
    super.key,
    required this.checkIns,
    this.weeksToShow = 16, // Shows ~110 days, fits nicely on most screens
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // 1. Calculate date range
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfCurrentWeek = PhantomDateHelpers.weekStart(today);
    // Find the Monday of the week weeksToShow ago
    final startDate = startOfCurrentWeek.subtract(Duration(days: (weeksToShow - 1) * 7));

    // 2. Generate all days to show, grouped by week (column-based)
    final List<List<DateTime>> weeks = [];
    var currentDay = startDate;
    for (int w = 0; w < weeksToShow; w++) {
      final List<DateTime> weekDays = [];
      for (int d = 0; d < 7; d++) {
        weekDays.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }
      weeks.add(weekDays);
    }

    // 3. Index check-ins by date (midnight) for quick lookup
    final Map<DateTime, List<CheckIn>> checkInsByDay = {};
    for (final ci in checkIns) {
      final day = DateTime(ci.timestamp.year, ci.timestamp.month, ci.timestamp.day);
      checkInsByDay.putIfAbsent(day, () => []).add(ci);
    }

    // Days of week labels (M, W, F)
    final dayLabels = ['M', '', 'W', '', 'F', '', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid Layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Labels (M, W, F)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  return Container(
                    height: 15,
                    alignment: Alignment.centerRight,
                    child: Text(
                      dayLabels[index],
                      style: textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Columns (Weeks)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // scroll to show latest days first
                child: Row(
                  children: weeks.map((week) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        children: week.map((day) {
                          final dayCheckIns = checkInsByDay[day] ?? [];
                          final hasLogged = dayCheckIns.isNotEmpty;

                          // Determine cell color based on effort levels
                          Color cellColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
                          if (hasLogged) {
                            // Find max effort level on this day
                            final maxEffort = dayCheckIns.map((c) => c.effortLevel).reduce((a, b) => a > b ? a : b);
                            switch (maxEffort) {
                              case EffortLevel.light:
                                cellColor = theme.colorScheme.primary.withOpacity(0.35);
                                break;
                              case EffortLevel.moderate:
                                cellColor = theme.colorScheme.primary.withOpacity(0.65);
                                break;
                              case EffortLevel.deep:
                                cellColor = theme.colorScheme.primary;
                                break;
                              default:
                                cellColor = theme.colorScheme.primary.withOpacity(0.35);
                            }
                          }

                          // If day is in the future, make it transparent
                          final isFuture = day.isAfter(today);
                          if (isFuture) {
                            cellColor = Colors.transparent;
                          }

                          return GestureDetector(
                            onTap: () {
                              if (hasLogged) {
                                _showDayLogs(context, day, dayCheckIns);
                              }
                            },
                            child: Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.symmetric(vertical: 1.5),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Legend Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            _buildLegendBox(theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)),
            const SizedBox(width: 3),
            _buildLegendBox(theme.colorScheme.primary.withOpacity(0.35)),
            const SizedBox(width: 3),
            _buildLegendBox(theme.colorScheme.primary.withOpacity(0.65)),
            const SizedBox(width: 3),
            _buildLegendBox(theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'More',
              style: textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  void _showDayLogs(BuildContext context, DateTime date, List<CheckIn> logs) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            PhantomDateHelpers.formatDate(date),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            EffortLevel.label(log.effortLevel).toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        if (log.durationMinutes != null)
                          Text(
                            '${log.durationMinutes} min',
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.note,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
